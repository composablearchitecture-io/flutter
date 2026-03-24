import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:composable_architecture_core/src/utils/action_buffer.dart';
import 'package:composable_architecture_core/src/utils/effect_subscription.dart';

/// Type alias for reducers that do not require an environment.
///
/// Use with [Store.emptyEnvironment] when your reducer has no external
/// dependencies.
typedef EmptyEnvironment = void;

/// The runtime that holds application state, processes actions through a
/// [Reducer], and executes [Effect]s.
///
/// A Store is the central coordination point of the Composable Architecture.
/// It maintains the current state, dispatches actions to the reducer, and
/// manages the lifecycle of effects (including cancellation).
///
/// ## Creating a Store
///
/// ```dart
/// // With an environment (API clients, services, etc.)
/// final store = Store.initial(AppState(), appReducer, AppEnvironment());
///
/// // Without an environment
/// final store = Store.emptyEnvironment(0, counterReducer);
/// ```
///
/// ## Dispatching Actions
///
/// ```dart
/// store.send(CounterAction.increment);
/// ```
///
/// ## Observing State
///
/// ```dart
/// store.stateObservable.listen((state) => print(state));
/// ```
///
/// ## Scoping
///
/// Create child stores that project a subset of state and actions:
///
/// ```dart
/// final counterStore = appStore.scope(
///   toLocalState: (appState) => appState.counter,
///   toGlobalAction: (action) => AppAction.counter(action),
/// );
/// ```
class Store<S, A> {
  bool _isSending = false;

  /// The compiled reducer function that processes state and actions.
  final ({S state, Effect<A> effect}) Function(S, A) reducer;

  /// Buffer for actions dispatched during an active send cycle.
  final ActionBuffer<A> bufferedActions = ActionBuffer<A>();

  /// Manages registration and cancellation of in-flight effects.
  final CancellableEffectHandler cancellableEffectHandler = CancellableEffectHandler();
  final CurrentValueSubject<S> _subject;
  final CurrentValueSubject<A> _actionSubject = CurrentValueSubject.empty();
  final void Function(A)? _send;

  /// An [Observable] that emits the current state whenever it changes.
  Observable<S> get stateObservable => _subject;

  /// An [Observable] that emits each action as it is dispatched.
  Observable<A> get actionObservable => _actionSubject;

  /// Updates the current state and notifies all observers.
  set state(S state) => _subject.add(state);

  /// The current state held by this store.
  S get state => _subject.value;

  /// Creates a store with an [environment] that is closed over by the [reducer].
  ///
  /// The environment typically contains external dependencies such as API
  /// clients, databases, or analytics services.
  ///
  /// ```dart
  /// final store = Store.initial(
  ///   AppState(),
  ///   appReducer,
  ///   AppEnvironment(api: ApiClient()),
  /// );
  /// ```
  static Store<S, A> initial<S, A, Environment>(
    S initialState,
    Reducer<S, A, Environment> reducer,
    Environment environment,
  ) =>
      Store._(
        subject: CurrentValueSubject.create<S>(initialState),
        reducer: (state, action) => reducer.reduce(state, action, environment),
      );

  /// Creates a store for reducers that do not need an environment.
  ///
  /// This is a convenience constructor equivalent to calling [Store.initial]
  /// with a `null` environment.
  ///
  /// ```dart
  /// final store = Store.emptyEnvironment(0, counterReducer);
  /// ```
  static Store<S, A> emptyEnvironment<S, A>(
    S initialState,
    Reducer<S, A, EmptyEnvironment> reducer,
  ) =>
      Store._(
        subject: CurrentValueSubject.create<S>(initialState),
        reducer: (state, action) => reducer.reduce(state, action, null),
      );

  Store._({
    required CurrentValueSubject<S> subject,
    required this.reducer,
    void Function(A)? send,
  })  : _subject = subject,
        _send = send;

  /// Dispatches an [action] to the store's reducer.
  ///
  /// The reducer processes the action, producing a new state and an effect.
  /// The state is updated synchronously and observers are notified. The
  /// effect is then executed, which may emit further actions.
  ///
  /// Actions dispatched during an active send cycle (e.g., from effects)
  /// are buffered and processed sequentially.
  void send(A action) {
    if (_send != null) {
      return _send!(action);
    }
    bufferedActions.append(action);
    if (_isSending) return;
    _isSending = true;
    //LOOP FOR ALL BUFFERED ACTIONS
    while (bufferedActions.isNotEmpty) {
      final action = bufferedActions.removeLast();
      _actionSubject.add(action);
      try {
        final (state: newState, effect: effect) = reducer(
          state,
          action,
        );
        //UPDATE STATE
        state = newState;
        _isSending = false;

        effect.run(
          (
            emit: send,
            dispose: ({id, shouldCancel = true}) =>
                id != null ? cancellableEffectHandler.dispose(id, shouldCancel: shouldCancel) : null,
            register: (cancellable, {id, cancelInFlight = false}) => id != null
                ? cancellableEffectHandler.register(
                    id,
                    cancellable,
                    cancelInFlight,
                  )
                : null,
            guard: ({id}) => id != null ? cancellableEffectHandler.isUnique(id) : true,
          ),
        );
      } catch (e) {
        continue;
      }
    }
  }

  /// Creates a scoped child store that projects a subset of state and actions.
  ///
  /// The child store:
  /// - Derives its state from the parent via [toLocalState].
  /// - Forwards actions to the parent via [toGlobalAction].
  /// - Does not run its own reducer; all state changes flow through the parent.
  ///
  /// ```dart
  /// final counterStore = appStore.scope(
  ///   toLocalState: (app) => app.counter,
  ///   toGlobalAction: (action) => AppAction.counter(action),
  /// );
  /// ```
  Store<LocalState, LocalAction> scope<LocalState, LocalAction>({
    required LocalState Function(S globalState) toLocalState,
    required A Function(LocalAction localAction) toGlobalAction,
  }) {
    return Store._(
      subject: _subject.derive(toLocalState),
      reducer: (state, action) => (state: state, effect: Effect.none()),
      send: (localAction) => send(toGlobalAction(localAction)),
    );
  }

  /// Creates a scoped store that projects only the state, keeping the same
  /// action type.
  ///
  /// This is a convenience wrapper around [scope] for cases where actions
  /// do not need to be transformed.
  Store<LocalState, A> scopeState<LocalState>({
    required LocalState Function(S) toLocalState,
  }) =>
      scope(toLocalState: toLocalState, toGlobalAction: (action) => action);

  /// Creates a scoped store that transforms only the action type, keeping
  /// the same state.
  ///
  /// This is a convenience wrapper around [scope] for cases where state
  /// does not need to be projected.
  Store<S, LocalAction> scopeAction<LocalAction>({
    required A Function(LocalAction localAction) toGlobalAction,
  }) =>
      scope(
        toLocalState: (globalState) => globalState,
        toGlobalAction: toGlobalAction,
      );
}
