---
name: create-reducer
description: Create a Composable Architecture reducer with composition, pullback, forEach, and effect handling. Use when adding or composing reducers with composable_architecture_core.
argument-hint: <reducer-name> [--combine] [--forEach]
---

# Create Reducer

Generate a reducer following the Composable Architecture pattern. Works with the `composable_architecture_core` package. Reducers are pure functions `(State, Action, Environment) → (state: State, effect: Effect<Action>)`.

## Prerequisites

```yaml
dependencies:
  composable_architecture_core: ^0.1.0
```

## Data Class Strategy

Reducers themselves are always hand-written. However, the **state classes** that reducers operate on may use code generation:

- **freezed** (`freezed_annotation` in dependencies) → state uses `@freezed`; `copyWith` is generated
- **dart_mappable** (`dart_mappable` in dependencies) → state uses `@MappableClass()`; `copyWith` is generated
- **Neither present** → state has hand-written `copyWith`, `operator ==`, and `hashCode`

Check `pubspec.yaml` before generating state classes. The reducer code itself (`switch`, `copyWith` calls, effect returns) is identical regardless of the data class strategy.

## Conventions

1. Reducers return a named record `(state: S, effect: Effect<Action>)`
2. Use `const Effect.none()` when no side effects are needed
3. Pattern match exhaustively on sealed action classes
4. State classes need working `==`, `hashCode`, and `copyWith` — either via code generation or hand-written

## Basic Reducer

```dart
import 'package:composable_architecture_core/composable_architecture_core.dart';

final myReducer = Reducer<MyState, MyAction, MyEnvironment>(
  reduce: (state, action, env) {
    switch (action) {
      case MyActionIncrement _:
        return (
          state: state.copyWith(count: state.count + 1),
          effect: const Effect.none(),
        );
      case MyActionDecrement _:
        return (
          state: state.copyWith(count: state.count - 1),
          effect: const Effect.none(),
        );
    }
  },
);
```

## State-Only Reducer (no effects)

Use `Reducer.transform` when the reducer never produces effects:

```dart
final myReducer = Reducer<MyState, MyAction, MyEnvironment>.transform(
  (state, action, env) {
    switch (action) {
      case MyActionIncrement _:
        return state.copyWith(count: state.count + 1);
      case MyActionDecrement _:
        return state.copyWith(count: state.count - 1);
    }
  },
);
```

## Effect-Only Reducer (no state changes)

Use `Reducer.emit` for side-effect-only logic (analytics, logging):

```dart
final analyticsReducer = Reducer<MyState, MyAction, MyEnvironment>.emit(
  (state, action, env) {
    switch (action) {
      case MyActionIncrement _:
        return Effect.fireAndForget(() => env.analytics.track('increment'));
      default:
        return const Effect.none();
    }
  },
);
```

## Combining Reducers (`--combine`)

Compose multiple reducers into one. Each reducer processes the action, and their effects are merged:

```dart
final combinedReducer = Reducer.combine<MyState, MyAction, MyEnvironment>([
  featureReducer,
  analyticsReducer,
  loggingReducer,
]);
```

## Pullback (scope child reducer to parent)

Lift a child reducer to operate on parent state/actions using `Lens` and `ActionLens`:

```dart
// Lens: projects child state from parent
final stateLens = (
  get: (ParentState state) => state.child,
  set: (ParentState state, ChildState child) => state.copyWith(child: child),
);

// ActionLens: extracts/embeds child actions
final actionLens = (
  extract: (ParentAction action) =>
      action is ParentActionChild ? action.action : null,
  embed: (ChildAction value) => ParentAction.child(value),
);

// Pullback
final parentReducer = Reducer.combine<ParentState, ParentAction, ParentEnv>([
  childReducer.pullback(
    toChildState: stateLens,
    toChildAction: actionLens,
    toChildEnvironment: (env) => env.child,
  ),
  // ... other child reducers
]);
```

## ForEach — Collection Reduction (`--forEach`)

Reduce over a list of items using `Lens` + `Prism`:

```dart
// Prism: identifies elements by ID
final actionPrism = (
  extract: (ParentAction action) => action is ParentActionItem
      ? (action.id, action.action)
      : null,
  embed: (String id, ItemAction action) => ParentAction.item(id, action),
);

final parentReducer = itemReducer.forEach(
  stateLens: (
    get: (ParentState state) => state.items,
    set: (ParentState state, List<ItemState> items) =>
        state.copyWith(items: items),
  ),
  actionPrism: actionPrism,
  toChildEnvironment: (env) => env.item,
);
```

## Effect Patterns

```dart
// Async task returning an action
effect: Effect<MyAction>.task(() async {
  final result = await env.api.fetch();
  return MyAction.loaded(result);
})

// Fire and forget
effect: Effect<MyAction>.fireAndForget(() => env.logger.log('done'))

// Cancellable
effect: Effect<MyAction>.task(() async { ... }).cancellable('my-task')

// Cancel a running effect
effect: Effect.cancel('my-task')

// Delayed
effect: Effect.value(MyAction.timeout()).delay(Duration(seconds: 5))

// Stream
effect: Effect<MyAction>.stream(
  () => env.socket.messages.map((m) => MyAction.received(m)),
).cancellable('messages')

// Merge (parallel)
effect: Effect.merge([effect1, effect2])

// Concatenate (sequential)
effect: Effect.concatenate([effect1, effect2])

// Map action type
effect: childEffect.map((childAction) => MyAction.child(childAction))
```

## Checklist

- [ ] Checked `pubspec.yaml` for freezed / dart_mappable
- [ ] State class has working `==`, `hashCode`, and `copyWith` (generated or hand-written)
- [ ] Reducer handles all action cases exhaustively via `switch`
- [ ] Returns `(state:, effect:)` record (or uses `.transform`/`.emit` shorthand)
- [ ] Uses `const Effect.none()` when no side-effect needed
- [ ] Long-running effects are `.cancellable()` with a string ID
- [ ] Child reducers use `.pullback()` with Lens + ActionLens
- [ ] Collection reducers use `.forEach()` with Lens + Prism
- [ ] Multiple reducers composed with `Reducer.combine()`
- [ ] If code generation used: `build_runner build` executed
