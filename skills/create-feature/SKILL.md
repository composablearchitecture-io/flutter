---
name: create-feature
description: Scaffold a new Composable Architecture feature module with state, action, reducer, and page files. Use when the user wants to create a new feature, screen, or page using composable_architecture_core and composable_architecture_widgets.
argument-hint: <feature-name> [--with-route] [--with-effects]
---

# Create Feature

Generate a complete feature module following the Composable Architecture pattern for Dart/Flutter. This skill works with the `composable_architecture_core` and `composable_architecture_widgets` packages.

The user provides a feature name (e.g., `profile`, `settings`). Optionally include route integration (`--with-route`) or effect examples (`--with-effects`).

## Prerequisites

The project must depend on:
- `composable_architecture_core` — for Store, Reducer, Effect, Lens
- `composable_architecture_widgets` — for WithStore, IfLetStore, ForEachStore widgets
- `composable_architecture_router` — only if `--with-route` is used

## Data Class Strategy

**Before generating code**, check the project's `pubspec.yaml` for a data class library:

- **freezed** (`freezed_annotation` in dependencies) → use `@freezed` annotations; `copyWith`, `==`, `hashCode` are generated
- **dart_mappable** (`dart_mappable` in dependencies) → use `@MappableClass()` annotations; `copyWith`, `==`, `hashCode` are generated
- **Neither present** → hand-write `copyWith`, `operator ==`, and `hashCode`

This choice affects **state classes** and **route state classes**. Actions always use hand-written `sealed class` with concrete subclasses (freezed/dart_mappable can optionally be used for actions too, but the manual pattern is preferred for exhaustive `switch`).

## File Structure

Create files using `part`/`part of` barrel file convention:

```
lib/pages/<feature_name>/
├── <feature_name>.dart          # Barrel file with part directives
├── <feature_name>.store.dart    # State, Action, Reducer, Environment, Lens
└── <feature_name>.page.dart     # Widget with WithStore binding
```

## Conventions

1. State classes need working `==` and `hashCode` — either via code generation or hand-written
2. Actions use `sealed class` with factory constructors and concrete subclasses
3. Reducers return `(state: S, effect: Effect<Action>)` named tuples
4. Files within a feature use `part`/`part of` — not separate imports
5. Widgets use `WithStore` from `composable_architecture_widgets` for store binding
6. Store files are named `<feature>.store.dart`, page files `<feature>.page.dart`

## Barrel File (`<feature>.dart`)

```dart
library <feature_name>;

import 'package:flutter/material.dart';
import 'package:composable_architecture_widgets/composable_architecture_widgets.dart';

part '<feature_name>.store.dart';
part '<feature_name>.page.dart';
```

If using **freezed**, also add:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '<feature_name>.freezed.dart';
```

If using **dart_mappable**, also add:

```dart
import 'package:dart_mappable/dart_mappable.dart';

part '<feature_name>.mapper.dart';
```

## State — Without code generation (`<feature>.store.dart`)

```dart
part of '<feature_name>.dart';

class <Feature>State {
  final int count;
  final String name;

  const <Feature>State({required this.count, required this.name});

  <Feature>State copyWith({int? count, String? name}) =>
      <Feature>State(count: count ?? this.count, name: name ?? this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is <Feature>State &&
          runtimeType == other.runtimeType &&
          count == other.count &&
          name == other.name;

  @override
  int get hashCode => Object.hash(count, name);
}
```

For single-field state, use `field.hashCode` directly instead of `Object.hash`.

## State — With freezed (`<feature>.store.dart`)

```dart
part of '<feature_name>.dart';

@freezed
abstract class <Feature>State with _$<Feature>State {
  const factory <Feature>State({
    required int count,
    required String name,
  }) = _<Feature>State;
}
```

Freezed generates `copyWith`, `==`, `hashCode`, and `toString`.

## State — With dart_mappable (`<feature>.store.dart`)

```dart
part of '<feature_name>.dart';

@MappableClass()
class <Feature>State with <Feature>StateMappable {
  final int count;
  final String name;

  const <Feature>State({required this.count, required this.name});
}
```

dart_mappable generates `copyWith`, `==`, `hashCode`, and `toString`.

## Actions (`<feature>.store.dart`)

Actions always use the manual sealed class pattern regardless of code generation choice:

```dart
sealed class <Feature>Action {
  const <Feature>Action();

  const factory <Feature>Action.increment() = <Feature>ActionIncrement;
  const factory <Feature>Action.setName(String name) = <Feature>ActionSetName;
}

class <Feature>ActionIncrement extends <Feature>Action {
  const <Feature>ActionIncrement() : super();
}

class <Feature>ActionSetName extends <Feature>Action {
  final String name;
  const <Feature>ActionSetName(this.name) : super();
}
```

## Environment (`<feature>.store.dart`)

```dart
class <Feature>Environment {
  // Add dependencies here (API clients, services, etc.)
}
```

## Reducer (`<feature>.store.dart`)

```dart
final <feature>Reducer = Reducer<<Feature>State, <Feature>Action, <Feature>Environment>(
  reduce: (state, action, env) {
    switch (action) {
      case <Feature>ActionIncrement _:
        return (
          state: state.copyWith(count: state.count + 1),
          effect: const Effect.none(),
        );
      case <Feature>ActionSetName action:
        return (
          state: state.copyWith(name: action.name),
          effect: const Effect.none(),
        );
    }
  },
);
```

## Lens & ActionLens (`<feature>.store.dart`)

Define these for composing the feature into a parent:

```dart
class <Feature>StateLens {
  static Lens<ParentState, <Feature>State> <feature> = (
    get: (state) => state.<feature>,
    set: (state, <feature>) => state.copyWith(<feature>: <feature>),
  );
}

class <Feature>ActionLens {
  static ActionLens<ParentAction, <Feature>Action> <feature> = (
    extract: (action) => action is ParentAction<Feature> ? action.action : null,
    embed: (value) => ParentAction.<feature>(value),
  );
}
```

## Page (`<feature>.page.dart`)

```dart
part of '<feature_name>.dart';

class <Feature>Page extends StatelessWidget {
  final Store<<Feature>State, <Feature>Action> store;

  const <Feature>Page({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return WithStore<<Feature>State, <Feature>Action>(
      store: store,
      builder: (context, state, send) {
        return Scaffold(
          appBar: AppBar(title: Text('<Feature>')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Count: ${state.count}'),
                Text('Name: ${state.name}'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => send(const <Feature>Action.increment()),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
```

## If `--with-route` is specified

Add a `Routable` implementation and route state for `composable_architecture_router`:

### Route State — Without code generation

```dart
class <Feature>RouteState {
  final int id;
  const <Feature>RouteState(this.id);

  <Feature>RouteState copyWith({int? id}) =>
      <Feature>RouteState(id ?? this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is <Feature>RouteState && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

### Route State — With freezed

```dart
@freezed
abstract class <Feature>RouteState with _$<Feature>RouteState {
  const factory <Feature>RouteState({required int id}) = _<Feature>RouteState;
}
```

### Route State — With dart_mappable

```dart
@MappableClass()
class <Feature>RouteState with <Feature>RouteStateMappable {
  final int id;
  const <Feature>RouteState(this.id);
}
```

### Routable

```dart
class <Feature> extends Routable<AppState, <Feature>RouteState, <Feature>State,
    AppAction, <Feature>Action, AppEnvironment, <Feature>Environment> {

  @override
  RouteID id(<Feature>RouteState state) => '<feature>_${state.id}';

  @override
  Reducer<<Feature>State, <Feature>Action, <Feature>Environment> reducer() =>
      <feature>Reducer;

  @override
  Widget build(BuildContext context, Store<<Feature>State?, <Feature>Action> store,
      NestedNavigator nested) {
    return IfLetStore<<Feature>State, <Feature>Action>(
      store: store,
      builder: (context, store) => <Feature>Page(store: store),
    );
  }

  @override
  (RouteID, <Feature>Action)? extractAction(AppAction action) =>
      action is AppAction<Feature> ? (action.id, action.action) : null;

  @override
  AppAction toAppAction(RouteID id, <Feature>Action action) =>
      AppAction.<feature>(id, action);

  @override
  <Feature>State? buildLocalState(AppState appState, <Feature>RouteState routeState) =>
      <Feature>State(count: routeState.id, name: '');

  @override
  (AppState, <Feature>RouteState) setBackFromLocalState(
    AppState appState, <Feature>RouteState routeState, <Feature>State localState,
  ) => (appState, routeState);

  @override
  <Feature>Environment buildLocalEnvironment(AppEnvironment env) =>
      env.<feature>;

  @override
  Widget Function(BuildContext)? get whenNullState => null;

  @override
  Store<<Feature>State?, <Feature>Action> scope(
    RouteID id, Store<AppState, AppAction> store,
    AppState Function(AppState, <Feature>State?) setBack,
  ) {
    return store.scope(
      toChildState: (state) =>
          buildLocalState(state, state.navigation.routeStateForId(id)!),
      toChildAction: (action) => toAppAction(id, action),
      fromChildAction: (action) => extractAction(action)?.$2,
    );
  }
}
```

## If `--with-effects` is specified

Add async effect patterns to the reducer:

```dart
case <Feature>ActionLoadData _:
  return (
    state: state.copyWith(isLoading: true),
    effect: Effect<<Feature>Action>.task(() async {
      final data = await env.fetchData();
      return <Feature>Action.dataLoaded(data);
    }).cancellable('load-data'),
  );

case <Feature>ActionDataLoaded action:
  return (
    state: state.copyWith(isLoading: false, data: action.data),
    effect: const Effect.none(),
  );
```

## Post-Generation Steps

If using **freezed** or **dart_mappable**, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Checklist

- [ ] Checked `pubspec.yaml` for freezed / dart_mappable
- [ ] Barrel file with `part` directives created (including `.freezed.dart` or `.mapper.dart` if applicable)
- [ ] State class with working `==`, `hashCode`, and `copyWith` (generated or hand-written)
- [ ] Sealed action class with concrete subclasses
- [ ] Environment class (can be empty initially)
- [ ] Reducer handling all action cases exhaustively
- [ ] Lens and ActionLens defined for parent composition
- [ ] Page widget using `WithStore`
- [ ] If `--with-route`: Routable, route state (with proper equality), and router wiring
- [ ] If `--with-effects`: Async effects with cancellation
- [ ] If code generation used: `build_runner build` executed
