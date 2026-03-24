/// A pure Dart library for building applications using the Composable
/// Architecture pattern.
///
/// Provides unidirectional data flow with composable reducers, structured
/// effects, and first-class testability. No Flutter dependency required.
///
/// ## Core Types
///
/// - [Store] - Runtime that holds state, processes actions, and executes effects.
/// - [Reducer] - Pure function: `(State, Action, Env) -> (State, Effect)`.
/// - [Effect] - Description of a unit of work (async tasks, streams, cancellation).
/// - [Lens], [ActionLens], [Prism] - Optics for modular state/action decomposition.
/// - [CurrentValueSubject] - Observable that holds and emits its current value.
/// - [TestStore] - Testing wrapper that records state changes and actions.
///
/// ## Example
///
/// ```dart
/// enum CounterAction { increment, decrement }
///
/// final counterReducer = Reducer<int, CounterAction, EmptyEnvironment>.transform(
///   (state, action, env) => switch (action) {
///     CounterAction.increment => state + 1,
///     CounterAction.decrement => state - 1,
///   },
/// );
///
/// final store = Store.emptyEnvironment(0, counterReducer);
/// store.send(CounterAction.increment);
/// print(store.state); // 1
/// ```
library;

export 'src/store.dart';
export 'src/test_store.dart';
export 'src/effect.dart';
export 'src/reducer.dart';
export 'src/utils/lens.dart';
export 'src/utils/current_value_subject.dart';
