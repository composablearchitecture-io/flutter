import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:composable_architecture_core/src/utils/iterable_ext.dart';

/// A pure function that processes an action against the current state and
/// returns the new state along with any [Effect]s to execute.
///
/// Reducers are the heart of the Composable Architecture. They are pure,
/// deterministic, and composable. A reducer never performs side effects
/// directly; instead, it returns [Effect] values that describe the work
/// to be done.
///
/// ## Creating Reducers
///
/// ```dart
/// // State-only transformation (no effects)
/// final counterReducer = Reducer<int, CounterAction, EmptyEnvironment>.transform(
///   (state, action, env) => switch (action) {
///     CounterAction.increment => state + 1,
///     CounterAction.decrement => state - 1,
///   },
/// );
///
/// // Full reducer with effects
/// final userReducer = Reducer<UserState, UserAction, UserEnv>(
///   reduce: (state, action, env) => switch (action) {
///     LoadUser() => (
///       state: state.copyWith(isLoading: true),
///       effect: Effect.task(() => env.api.fetchUser())
///         .map((user) => UserAction.loaded(user)),
///     ),
///     UserLoaded(:final user) => (
///       state: state.copyWith(user: user, isLoading: false),
///       effect: Effect.none(),
///     ),
///   },
/// );
/// ```
///
/// ## Composition
///
/// Reducers compose via [combine], [pullback], [forEach], and [ifLet]:
///
/// ```dart
/// final appReducer = Reducer.combine([
///   counterReducer.pullback(stateLens: ..., actionLens: ...),
///   userReducer.pullback(stateLens: ..., actionLens: ...),
/// ]);
/// ```
final class Reducer<State, Action, Environment> {
  /// The reduce function that processes `(state, action, environment)` and
  /// returns `(state, effect)`.
  final ({State state, Effect<Action> effect}) Function(
    State state,
    Action action,
    Environment environment,
  ) reduce;

  /// Creates a reducer with the given [reduce] function.
  const Reducer({required this.reduce});

  /// Creates a no-op reducer that returns the state unchanged and emits
  /// no effects.
  factory Reducer.empty() => Reducer(
        reduce: (state, action, env) => (
          state: state,
          effect: Effect.none(),
        ),
      );

  /// Creates a reducer that transforms state without producing effects.
  ///
  /// Use this for simple state transitions that don't require async work.
  ///
  /// ```dart
  /// final reducer = Reducer<int, Action, Env>.transform(
  ///   (state, action, env) => state + 1,
  /// );
  /// ```
  factory Reducer.transform(
    State Function(State state, Action action, Environment env) transformer,
  ) =>
      Reducer(
        reduce: (state, action, env) => (
          state: transformer(state, action, env),
          effect: Effect.none(),
        ),
      );

  /// Creates a reducer that emits effects without changing state.
  ///
  /// Use this for side-effect-only responses to actions (e.g., analytics,
  /// logging, navigation).
  factory Reducer.emit(
    Effect<Action> Function(State state, Action action, Environment env) emitter,
  ) =>
      Reducer(
        reduce: (state, action, env) => (
          state: state,
          effect: emitter(state, action, env),
        ),
      );

  /// Combines multiple reducers into one.
  ///
  /// Each reducer runs in order on the same action, threading state through
  /// sequentially. Effects from all reducers are merged for concurrent
  /// execution.
  ///
  /// ```dart
  /// final appReducer = Reducer.combine([
  ///   featureAReducer.pullback(...),
  ///   featureBReducer.pullback(...),
  /// ]);
  /// ```
  factory Reducer.combine(List<Reducer<State, Action, Environment>> reducers) => Reducer(
        reduce: (state, action, environment) {
          final List<Effect<Action>> effects = [];
          var s = state;
          for (final reducer in reducers) {
            final (state: newState, effect: effect) = reducer.reduce(
              s,
              action,
              environment,
            );
            effects.add(effect);
            s = newState;
          }
          return (state: s, effect: Effect.merge(effects: effects));
        },
      );

  /// Lifts this local reducer to operate within a larger global domain.
  ///
  /// Uses [stateLens] to read/write local state from/to global state,
  /// and [actionLens] to extract/embed local actions from/to global actions.
  /// Actions that don't match the lens are ignored (no state change, no effects).
  ///
  /// ```dart
  /// final globalReducer = localReducer.pullback(
  ///   stateLens: (get: (g) => g.local, set: (g, l) => g.copyWith(local: l)),
  ///   actionLens: (extract: (g) => g.local, embed: (l) => GlobalAction.local(l)),
  /// );
  /// ```
  Reducer<GlobalState, GlobalAction, GlobalEnvironment> pullback<GlobalState, GlobalAction, GlobalEnvironment>({
    required Lens<GlobalState, State> stateLens,
    required ActionLens<GlobalAction, Action> actionLens,
    Environment Function(GlobalEnvironment globalEnv)? toLocalEnvironment,
  }) {
    return _pullback(
      toLocalState: stateLens.get,
      toGlobalState: stateLens.set,
      toLocalAction: actionLens.extract,
      toGlobalAction: actionLens.embed,
      toLocalEnvironment: toLocalEnvironment ?? ((p0) => p0 as Environment),
    );
  }

  /// Same as [pullback] with explicit environment transformation.
  Reducer<GlobalState, GlobalAction, GlobalEnvironment> pullbackWithEnv<GlobalState, GlobalAction, GlobalEnvironment>({
    required Lens<GlobalState, State> stateLens,
    required ActionLens<GlobalAction, Action> actionLens,
    Environment Function(GlobalEnvironment globalEnv)? toLocalEnvironment,
  }) {
    return _pullback(
      toLocalState: stateLens.get,
      toGlobalState: stateLens.set,
      toLocalAction: actionLens.extract,
      toGlobalAction: actionLens.embed,
      toLocalEnvironment: toLocalEnvironment ?? ((p0) => p0 as Environment),
    );
  }

  /// Lifts this reducer to a global state domain while keeping the same
  /// action type. Useful when the action type is shared across domains.
  Reducer<GlobalState, Action, GlobalEnvironment> pullbackState<GlobalState, GlobalEnvironment>({
    required Lens<GlobalState, State> stateLens,
    Environment Function(GlobalEnvironment globalEnv)? toLocalEnvironment,
  }) {
    return _pullback(
      toLocalState: stateLens.get,
      toGlobalState: stateLens.set,
      toLocalAction: (p0) => p0,
      toGlobalAction: (p0) => p0,
      toLocalEnvironment: toLocalEnvironment ?? ((p0) => p0 as Environment),
    );
  }

  /// Lifts this reducer to a global action domain while keeping the same
  /// state type. Useful when the state is shared but actions differ.
  Reducer<State, GlobalAction, GlobalEnvironment> pullbackAction<GlobalAction, GlobalEnvironment>({
    required ActionLens<GlobalAction, Action> actionLens,
    Environment Function(GlobalEnvironment globalEnv)? toLocalEnvironment,
  }) {
    return _pullback(
      toLocalState: (state) => state,
      toGlobalState: (state, localState) => localState,
      toLocalAction: actionLens.extract,
      toGlobalAction: actionLens.embed,
      toLocalEnvironment: toLocalEnvironment ?? ((p0) => p0 as Environment),
    );
  }

  /// Conditionally applies [subReducer] when the current state is of type
  /// [SubState].
  ///
  /// This enables type-based state discrimination, useful when your state
  /// is a sealed class hierarchy. The sub-reducer only runs when the state
  /// matches the expected type.
  Reducer<State, Action, Environment> when<SubState>(
    Reducer<SubState, Action, Environment> subReducer,
  ) {
    return ifLet<SubState, Action, Environment>(
      stateLens: (
        get: (state) => state is SubState ? state as SubState : null,
        set: (state, localState) {
          if (localState is State) {
            return localState;
          } else {
            return state;
          }
        },
      ),
      actionLens: (
        embed: (localAction) => localAction,
        extract: (action) => action,
      ),
      toLocalEnvironment: (p0) => p0,
      child: subReducer,
    );
  }

  /// Internal implementation of pullback that maps state, actions, and
  /// environment between local and global domains.
  Reducer<GlobalState, GlobalAction, GlobalEnvironment> _pullback<GlobalState, GlobalAction, GlobalEnvironment>({
    required State Function(GlobalState) toLocalState,
    required GlobalState Function(GlobalState, State) toGlobalState,
    required Action? Function(GlobalAction) toLocalAction,
    required GlobalAction Function(Action) toGlobalAction,
    required Environment Function(GlobalEnvironment) toLocalEnvironment,
  }) {
    return Reducer<GlobalState, GlobalAction, GlobalEnvironment>(
      reduce: (state, action, environment) {
        final Action? localAction = toLocalAction(action);
        if (localAction == null) {
          return (state: state, effect: Effect.none());
        }
        final (state: newLocalState, effect: effect) = reduce(
          toLocalState(state),
          localAction,
          toLocalEnvironment(environment),
        );
        return (
          state: toGlobalState(state, newLocalState),
          effect: effect.map(
            (a) => toGlobalAction(a),
          ),
        );
      },
    );
  }

  /// Composes this reducer with a [child] reducer that operates on optional
  /// state.
  ///
  /// When the state projected through [stateLens] is non-null, the child
  /// reducer runs. When it is null, the child reducer is skipped. This
  /// combines both reducers, with this reducer running first.
  Reducer<State, Action, Environment> ifLet<ChildState, ChildAction, ChildEnvironment>({
    required Lens<State, ChildState?> stateLens,
    required ActionLens<Action, ChildAction> actionLens,
    ChildEnvironment Function(Environment)? toLocalEnvironment,
    required Reducer<ChildState, ChildAction, ChildEnvironment> child,
  }) {
    return Reducer.combine([
      this,
      child.nullable().pullback(
            stateLens: stateLens,
            actionLens: actionLens,
            toLocalEnvironment: toLocalEnvironment ?? ((p0) => p0 as ChildEnvironment),
          ),
    ]);
  }

  /// Wraps this reducer to handle nullable state.
  ///
  /// If the state is `null`, returns `null` state with no effects.
  /// Otherwise, delegates to the original reducer.
  Reducer<State?, Action, Environment> nullable() {
    return Reducer<State?, Action, Environment>(
      reduce: (state, action, environment) {
        if (state == null) {
          return (state: null, effect: Effect.none());
        }
        return reduce(state, action, environment);
      },
    );
  }

  /// Wraps this reducer to print each action, previous state, and new state
  /// to the console. Useful during development for tracing state changes.
  Reducer<State, Action, Environment> debug() {
    return Reducer<State, Action, Environment>(
      reduce: (state, action, environment) {
        final (state: newState, effect: effect) = reduce(state, action, environment);
        print('Action: $action');
        print('State: $state');
        print('New State: $newState');
        return (state: newState, effect: effect);
      },
    );
  }
}

/// Extension providing `forEach` variants for applying a reducer to each
/// element in a collection.
extension ForEachIterableReducer<State, Action, Environment> on Reducer<State, Action, Environment> {
  /// Applies this reducer to a specific element in a collection, identified
  /// by [toID].
  ///
  /// Uses [stateLens] to access the collection from global state and
  /// [actionPrism] to route actions to individual elements by ID.
  ///
  /// ```dart
  /// final listReducer = itemReducer.forEach(
  ///   stateLens: (get: (s) => s.items, set: (s, items) => s.copyWith(items: items)),
  ///   actionPrism: (
  ///     extract: (a) => switch (a) { ItemAction(id, a) => (id, a), _ => null },
  ///     embed: (id, a) => GlobalAction.item(id, a),
  ///   ),
  ///   toID: (item) => item.id,
  /// );
  /// ```
  Reducer<GlobalState, GlobalAction, GlobalEnvironment> forEach<GlobalState, GlobalAction, GlobalEnvironment, ID>({
    required Lens<GlobalState, Iterable<State>> stateLens,
    required Prism<GlobalAction, Action, ID> actionPrism,
    required ID Function(State state) toID,
    Environment Function(ID, GlobalEnvironment)? toLocalEnvironment,
  }) {
    State? cachedState;
    return Reducer<GlobalState, GlobalAction, GlobalEnvironment>(
      reduce: (state, action, environment) {
        final extracted = actionPrism.extract(action);
        if (extracted == null) {
          return (state: state, effect: Effect.none());
        }
        final (id, localAction) = extracted;
        final iterable = stateLens.get(state);
        final localState = iterable.where((element) => toID(element) == id).firstOrNull ?? cachedState;
        assert(localState != null, """
        A "forEach" received an action for a missing element. …

          ID: $id
          Action: $localAction

        This is generally considered an application logic error, and can happen for a few reasons:

        • A parent reducer removed an element with this ID before this reducer ran. This reducer
        must run before any other reducer removes an element, which ensures that element reducers
        can handle their actions while their state is still available.

        • An in-flight effect emitted this action when state contained no element at this ID.
        While it may be perfectly reasonable to ignore this action, consider canceling the
        associated effect before an element is removed, especially if it is a long-living effect.

        • This action was sent to the store while its state contained no element at this ID. To
        fix this make sure that actions for this reducer can only be sent from a view store when
        its state contains an element at this id. In SwiftUI applications, use "ForEachStore".
        """);
        cachedState = localState;
        final (state: newLocalState, effect: effect) = reduce(
          localState as State,
          localAction,
          toLocalEnvironment == null ? environment as Environment : toLocalEnvironment(id, environment),
        );
        return (
          state: stateLens.set(
            state,
            iterable.map((e) => toID(e) == id ? newLocalState : e),
          ),
          effect: effect.map((e) => actionPrism.embed(id, e)),
        );
      },
    );
  }

  /// Like [forEach], but identifies elements by their index in the collection
  /// rather than a custom ID function.
  Reducer<GlobalState, GlobalAction, GlobalEnvironment> forEachIndexed<GlobalState, GlobalAction, GlobalEnvironment>({
    required Lens<GlobalState, Iterable<State>> stateLens,
    required Prism<GlobalAction, Action, int> actionPrism,
    required Environment Function(int, GlobalEnvironment) toLocalEnvironment,
  }) {
    State? cachedState;
    return Reducer<GlobalState, GlobalAction, GlobalEnvironment>(
      reduce: (state, action, environment) {
        final extracted = actionPrism.extract(action);
        if (extracted == null) {
          return (state: state, effect: Effect.none());
        }
        final (id, localAction) = extracted;
        final iterable = stateLens.get(state);
        final localState = iterable.whereIndexed((index, element) => index == id).firstOrNull ?? cachedState;
        assert(localState != null, """
        A "forEach" received an action for a missing element. …

          ID: $id
          Action: $localAction

        This is generally considered an application logic error, and can happen for a few reasons:

        • A parent reducer removed an element with this ID before this reducer ran. This reducer
        must run before any other reducer removes an element, which ensures that element reducers
        can handle their actions while their state is still available.

        • An in-flight effect emitted this action when state contained no element at this ID.
        While it may be perfectly reasonable to ignore this action, consider canceling the
        associated effect before an element is removed, especially if it is a long-living effect.

        • This action was sent to the store while its state contained no element at this ID. To
        fix this make sure that actions for this reducer can only be sent from a view store when
        its state contains an element at this id. In SwiftUI applications, use "ForEachStore".
        """);
        cachedState = localState;
        final (state: newLocalState, effect: effect) = reduce(
          localState as State,
          localAction,
          toLocalEnvironment(id, environment),
        );
        return (
          state: stateLens.set(
            state,
            iterable.mapIndexed((index, e) => index == id ? newLocalState : e),
          ),
          effect: effect.map((e) => actionPrism.embed(id, e)),
        );
      },
    );
  }

  /// Like [forEach], but operates on a `Map<ID, State>` instead of an
  /// `Iterable<State>`.
  Reducer<GlobalState, GlobalAction, GlobalEnvironment> forEachMap<GlobalState, GlobalAction, GlobalEnvironment, ID>({
    required Map<ID, State> Function(GlobalState) toMapState,
    required GlobalState Function(GlobalState, Map<ID, State>) toGlobalState,
    required (ID, Action)? Function(GlobalAction) toLocalAction,
    required GlobalAction Function(ID, Action) toGlobalAction,
    required Environment Function(ID, GlobalEnvironment) toLocalEnvironment,
  }) {
    return Reducer<GlobalState, GlobalAction, GlobalEnvironment>(
      reduce: (state, action, environment) {
        final extracted = toLocalAction(action);
        if (extracted == null) {
          return (state: state, effect: Effect.none());
        }
        final (id, localAction) = extracted;
        final map = toMapState(state);
        final localState = map[id];
        assert(localState != null, """
        A "forEach" received an action for a missing element. …

          ID: $id
          Action: $localAction

        This is generally considered an application logic error, and can happen for a few reasons:

        • A parent reducer removed an element with this ID before this reducer ran. This reducer
        must run before any other reducer removes an element, which ensures that element reducers
        can handle their actions while their state is still available.

        • An in-flight effect emitted this action when state contained no element at this ID.
        While it may be perfectly reasonable to ignore this action, consider canceling the
        associated effect before an element is removed, especially if it is a long-living effect.

        • This action was sent to the store while its state contained no element at this ID. To
        fix this make sure that actions for this reducer can only be sent from a view store when
        its state contains an element at this id. In SwiftUI applications, use "ForEachStore".
        """);
        final (state: newLocalState, effect: effect) = reduce(
          // ignore: null_check_on_nullable_type_parameter
          localState!,
          localAction,
          toLocalEnvironment(id, environment),
        );
        return (
          state: toGlobalState(
            state,
            map.map(
              (key, value) => MapEntry(key, key == id ? newLocalState : value),
            ),
          ),
          effect: effect.map((e) => toGlobalAction(id, e)),
        );
      },
    );
  }
}
