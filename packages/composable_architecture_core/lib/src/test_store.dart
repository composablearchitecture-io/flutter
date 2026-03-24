import 'package:composable_architecture_core/src/reducer.dart';
import 'package:composable_architecture_core/src/store.dart';

/// A testing wrapper around [Store] that records all dispatched actions and
/// state changes for easy assertions.
///
/// Use `TestStore` to verify that your reducer produces the expected state
/// transitions and effects in response to actions.
///
/// ## Example
///
/// ```dart
/// final testStore = TestStore(0, counterReducer, null);
///
/// testStore.send(CounterAction.increment);
/// expect(testStore.states, [0, 1]);
/// expect(testStore.actions, [CounterAction.increment]);
///
/// testStore.send(
///   CounterAction.increment,
///   expected: (state) => expect(state, 2),
/// );
/// ```
class TestStore<State, Action, Environment> {
  late final Store<State, Action> _store;

  /// All actions that have been dispatched to this store, in order.
  List<Action> actions = [];

  /// All state values observed by this store, in order.
  ///
  /// Includes the initial state (unless [skipInitialState] was set to `true`).
  List<State> states = [];

  /// Creates a test store with the given [initialState], [reducer], and
  /// [environment].
  ///
  /// If [skipInitialState] is `true`, the initial state is not recorded
  /// in [states].
  TestStore(
    State initialState,
    Reducer<State, Action, Environment> reducer,
    Environment environment, {
    bool skipInitialState = false,
  }) {
    _store = Store.initial(
      initialState,
      Reducer<State, Action, Environment>(
        reduce: (state, action, env) {
          actions.add(action);
          return reducer.reduce(state, action, env);
        },
      ),
      environment,
    );
    _store.stateObservable.listen((e) => states.add(e), fireImmediately: !skipInitialState);
  }

  /// Dispatches an [action] and optionally asserts the resulting state via
  /// [expected].
  ///
  /// ```dart
  /// testStore.send(
  ///   CounterAction.increment,
  ///   expected: (state) => expect(state, 1),
  /// );
  /// ```
  void send(Action action, {void Function(State)? expected}) {
    _store.send(action);
    expected?.call(_store.state);
  }

  /// Dispatches a sequence of actions with delays between each.
  ///
  /// Each entry is a tuple of `(action, delay)`. The delay is applied
  /// before sending each action. Useful for testing time-dependent effects.
  ///
  /// ```dart
  /// await testStore.sendSequence([
  ///   (CounterAction.increment, Duration(milliseconds: 100)),
  ///   (CounterAction.increment, Duration(milliseconds: 100)),
  /// ]);
  /// ```
  Future<void> sendSequence(
    List<(Action action, Duration duration)> actions,
  ) async {
    for (final action in actions) {
      await Future.delayed(action.$2);
      Future.microtask(() => _store.send(action.$1));
    }
  }

  /// Asserts the current state using the [expected] callback.
  void checkState(void Function(State) expected) {
    expected(_store.state);
    Reducer<int?, dynamic, dynamic>.empty();
  }
}
