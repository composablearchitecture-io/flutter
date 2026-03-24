# composable_architecture_core

A pure Dart library for building applications using the Composable Architecture pattern. Inspired by [Point-Free's TCA](https://github.com/pointfreeco/swift-composable-architecture), it provides a unidirectional data flow with composable reducers, structured effects, and first-class testability.

**Zero dependencies.** Works in any Dart environment - Flutter, server-side, CLI, or standalone.

## Core Concepts

### Store

The runtime that holds your application state, processes actions through a reducer, and executes effects:

```dart
final store = Store.emptyEnvironment(
  0,                // initial state
  counterReducer,   // reducer
);

store.send(CounterAction.increment);
print(store.state); // 1
```

For reducers that need dependencies (API clients, databases, etc.), use `Store.initial`:

```dart
final store = Store.initial(
  AppState(),
  appReducer,
  AppEnvironment(apiClient: ApiClient()),
);
```

### Reducer

A pure function that takes the current state, an action, and an environment, then returns the new state and any effects to execute:

```dart
final counterReducer = Reducer<int, CounterAction, EmptyEnvironment>.transform(
  (state, action, env) => switch (action) {
    CounterAction.increment => state + 1,
    CounterAction.decrement => state - 1,
    CounterAction.reset => 0,
  },
);
```

When you need to perform side effects, return both state and effects:

```dart
final userReducer = Reducer<UserState, UserAction, UserEnvironment>(
  reduce: (state, action, env) => switch (action) {
    LoadUser() => (
      state: state.copyWith(isLoading: true),
      effect: Effect.future(() => env.api.fetchUser())
        .map((user) => UserAction.userLoaded(user)),
    ),
    UserLoaded(:final user) => (
      state: state.copyWith(isLoading: false, user: user),
      effect: Effect.none(),
    ),
  },
);
```

#### Reducer Factories

| Factory | Description |
|---|---|
| `Reducer.transform(fn)` | State transformation, no effects |
| `Reducer.emit(fn)` | Effect emission, no state change |
| `Reducer.combine([...])` | Merges multiple reducers |
| `Reducer.empty()` | No-op reducer |

### Effect

A description of a unit of work. Effects are values - they describe what to do, not how to do it. The store handles execution.

```dart
// Async work
Effect.future(() async => await api.fetchData())

// Synchronous value
Effect.value(SomeAction.loaded(data))

// No work
Effect.none()

// Compose effects
Effect.merge([effect1, effect2])      // run concurrently
Effect.concatenate([effect1, effect2]) // run sequentially

// Fire and forget (run but ignore result)
effect.fireAndForget()

// Cancellation
effect.cancellable(id: "search", cancelInFlight: true)

// Timing
effect.debounce(id: "search", interval: Duration(milliseconds: 300))
effect.throttle(id: "scroll", interval: Duration(milliseconds: 100))
effect.delay(Duration(seconds: 1))

// Composition
effect.map((value) => SomeAction.loaded(value))
effect.flatMap((value) => Effect.future(() => transform(value)))
```

#### Effect Types

| Type | Description |
|---|---|
| `Effect.none()` | No-op |
| `Effect.value(v)` | Emit a synchronous value |
| `Effect.future(fn)` | Async computation |
| `Effect.stream(stream)` | Bridge a Dart Stream |
| `Effect.run(fn)` | Synchronous computation with error handling |
| `Effect.merge([...])` | Concurrent execution |
| `Effect.concatenate([...])` | Sequential execution |
| `Effect.periodic(interval, fn)` | Emit on fixed interval |
| `Effect.cancel(id)` | Cancel an in-flight effect |

### Composition

The key feature: building large applications from small, isolated modules.

#### Pullback

Lift a local reducer to work within a larger state/action domain using lenses:

```dart
// Define lenses for state and action mapping
Lens<AppState, CounterState> counterStateLens = (
  get: (appState) => appState.counter,
  set: (appState, counter) => appState.copyWith(counter: counter),
);

ActionLens<AppAction, CounterAction> counterActionLens = (
  extract: (appAction) => switch (appAction) {
    AppAction.counter(action) => action,
    _ => null,
  },
  embed: (counterAction) => AppAction.counter(counterAction),
);

// Pullback the local reducer to the global domain
final appReducer = counterReducer.pullback(
  stateLens: counterStateLens,
  actionLens: counterActionLens,
);
```

#### Combine

Merge multiple reducers for the same state/action type:

```dart
final appReducer = Reducer.combine([
  featureAReducer.pullback(...),
  featureBReducer.pullback(...),
  globalReducer,
]);
```

#### ForEach

Apply a reducer to each element in a collection:

```dart
final listReducer = itemReducer.forEach(
  stateLens: itemsLens,
  actionPrism: itemPrism,
  toID: (item) => item.id,
  toLocalEnvironment: (_, env) => env,
);
```

#### Store Scoping

Create child stores that project a subset of state and actions:

```dart
final counterStore = appStore.scope(
  toLocalState: (appState) => appState.counter,
  toGlobalAction: (counterAction) => AppAction.counter(counterAction),
);
```

### Optics

Type-safe accessors for decomposing state and actions:

```dart
// Lens: bidirectional state access
typedef Lens<GlobalState, LocalState> = ({
  LocalState Function(GlobalState) get,
  GlobalState Function(GlobalState, LocalState) set,
});

// ActionLens: action filtering and embedding
typedef ActionLens<GlobalAction, LocalAction> = ({
  LocalAction? Function(GlobalAction) extract,
  GlobalAction Function(LocalAction) embed,
});

// Prism: for keyed collections
typedef Prism<GlobalAction, LocalAction, ID> = ({
  (ID, LocalAction)? Function(GlobalAction) extract,
  GlobalAction Function(ID, LocalAction) embed,
});
```

### Observable

A lightweight reactive primitive powering Store's state and action streams:

```dart
store.stateObservable
  .map((state) => state.count)
  .distinct()
  .when((count) => count > 0)
  .listen((count) => print('Positive count: $count'));
```

Operators: `map`, `distinct`, `when` (filter).

`CurrentValueSubject<T>` is the concrete implementation - an observable that holds and emits its current value.

## Testing

`TestStore` records all state changes and dispatched actions for easy assertions:

```dart
final testStore = TestStore(
  0,                // initial state
  counterReducer,   // reducer
  null,             // environment
);

testStore.send(CounterAction.increment);
expect(testStore.states, [0, 1]);
expect(testStore.actions, [CounterAction.increment]);

// Assert expected state inline
testStore.send(
  CounterAction.increment,
  expected: (state) => expect(state, 2),
);

// Test async sequences with timing
await testStore.sendSequence([
  (CounterAction.increment, Duration(milliseconds: 100)),
  (CounterAction.increment, Duration(milliseconds: 100)),
]);
```

## Data Flow

```
store.send(action)
    |
    v
ActionBuffer (queues nested sends)
    |
    v
Reducer: (state, action, env) -> (newState, effect)
    |               |
    v               v
Update state    Execute effect
    |               |
    v               v
Notify          emit(action) -> re-enters send()
observers       register/dispose/guard cancellables
```

## Installation

```yaml
dependencies:
  composable_architecture_core: ^0.1.0
```

## Requirements

- Dart SDK >= 3.0.6
