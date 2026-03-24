/// A bidirectional accessor for reading and writing a [LocalState] within a
/// [GlobalState].
///
/// Lenses enable modular state decomposition. They are used with
/// [Reducer.pullback] to lift a local reducer into a global state domain.
///
/// - [get] extracts the local state from the global state.
/// - [set] returns a new global state with the local state updated.
///
/// ```dart
/// Lens<AppState, int> counterLens = (
///   get: (app) => app.counter,
///   set: (app, counter) => app.copyWith(counter: counter),
/// );
/// ```
typedef Lens<GlobalState, LocalState> = ({
  LocalState Function(GlobalState state) get,
  GlobalState Function(GlobalState state, LocalState localState) set,
});

/// A bidirectional accessor for filtering and embedding a [LocalAction]
/// within a [GlobalAction].
///
/// Used with [Reducer.pullback] to route global actions to local reducers.
///
/// - [extract] returns the local action if the global action matches,
///   or `null` to skip.
/// - [embed] wraps a local action into a global action.
///
/// ```dart
/// ActionLens<AppAction, CounterAction> counterActionLens = (
///   extract: (a) => switch (a) { AppAction.counter(a) => a, _ => null },
///   embed: (a) => AppAction.counter(a),
/// );
/// ```
typedef ActionLens<GlobalAction, LocalAction> = ({
  LocalAction? Function(GlobalAction action) extract,
  GlobalAction Function(LocalAction localAction) embed,
});

/// A keyed variant of [ActionLens] for routing actions to elements in a
/// collection by [ID].
///
/// Used with [ForEachIterableReducer.forEach] to dispatch actions to
/// individual elements in a list or map.
///
/// - [extract] returns `(id, localAction)` if the global action targets a
///   collection element, or `null` to skip.
/// - [embed] wraps a local action with its element ID into a global action.
///
/// ```dart
/// Prism<AppAction, ItemAction, String> itemPrism = (
///   extract: (a) => switch (a) { EditItem(id, a) => (id, a), _ => null },
///   embed: (id, a) => AppAction.editItem(id, a),
/// );
/// ```
typedef Prism<GlobalAction, LocalAction, ID> = ({
  (ID, LocalAction)? Function(GlobalAction action) extract,
  GlobalAction Function(ID id, LocalAction localAction) embed,
});

/// A lens that operates on state composed from both a [GlobalState] and a
/// [RouteState].
///
/// Used in navigation scenarios where the local state depends on both the
/// app state and the current route state.
typedef RouteLens<GlobalState, RouteState, LocalState> = ({
  LocalState Function(GlobalState global, RouteState route) get,
  (GlobalState, RouteState) Function(
    GlobalState global,
    RouteState route,
    LocalState local,
  ) set,
});
