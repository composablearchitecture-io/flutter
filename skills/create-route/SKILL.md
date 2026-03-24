---
name: create-route
description: Create a composable architecture route with Routable, bindings, guards, and navigation. Use when adding a new screen/route with composable_architecture_router.
argument-hint: <route-name> [--tabs] [--sheet] [--dialog]
---

# Create Route

Generate a complete route for the Composable Architecture router. Works with the `composable_architecture_router` package. This creates a route folder with all required files, wires it into the app reducer, and registers the action.

## Prerequisites

```yaml
dependencies:
  composable_architecture_router: ^0.1.0
```

## Data Class Strategy

**Before generating code**, check the project's `pubspec.yaml` for a data class library:

- **freezed** (`freezed_annotation` in dependencies) → use `@freezed` for state/route state; `copyWith`, `==`, `hashCode` are generated. Classes must be declared `abstract`.
- **dart_mappable** (`dart_mappable` in dependencies) → use `@MappableClass()` for state/route state; `copyWith`, `==`, `hashCode` are generated
- **Neither present** → hand-write `copyWith`, `operator ==`, and `hashCode`

## Folder Structure

Each route lives in `lib/routes/<name>/`:

```
lib/routes/<name>/
├── <name>.dart           # Barrel file with imports and part directives
├── <name>.core.dart      # State, RouteState, Action, Environment
├── <name>.route.dart     # Routable subclass with routeLens, actionPrism, reducer
└── <name>.page.dart      # Widget
```

## File Contents

### `lib/routes/<name>/<name>.dart` (Barrel File)

```dart
import 'package:composable_architecture_flutterw/material.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';
import 'package:flutter/material.dart';
import 'package:<app_name>/app/app.dart';

part '<name>.core.dart';
part '<name>.page.dart';
part '<name>.route.dart';
```

If using `--freezed`, also add:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '<name>.freezed.dart';
```

If using `--dart-mappable`, also add:

```dart
import 'package:dart_mappable/dart_mappable.dart';

part '<name>.mapper.dart';
```

### `lib/routes/<name>/<name>.core.dart` — Without code generation

```dart
part of '<name>.dart';

/////////////////
///// STATE /////
/////////////////
class <Name>State {
  final int count;

  const <Name>State({this.count = 0});

  <Name>State copyWith({int? count}) =>
      <Name>State(count: count ?? this.count);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is <Name>State && count == other.count;

  @override
  int get hashCode => count.hashCode;
}

/////////////////
// ROUTE STATE //
/////////////////
class <Name>RouteState {
  final int count;

  const <Name>RouteState({this.count = 0});

  <Name>RouteState copyWith({int? count}) =>
      <Name>RouteState(count: count ?? this.count);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is <Name>RouteState && count == other.count;

  @override
  int get hashCode => count.hashCode;
}

/////////////////
//// ACTION /////
/////////////////
sealed class <Name>Action {
  const <Name>Action();
}

class <Name>ActionIncrement extends <Name>Action {
  const <Name>ActionIncrement();
}

class <Name>ActionDecrement extends <Name>Action {
  const <Name>ActionDecrement();
}

/////////////////
// ENVIRONMENT //
/////////////////
class <Name>Environment {
  const <Name>Environment();
}
```

### `lib/routes/<name>/<name>.core.dart` — With freezed

```dart
part of '<name>.dart';

/////////////////
///// STATE /////
/////////////////
@freezed
abstract class <Name>State with _$<Name>State {
  const factory <Name>State({
    @Default(0) int count,
  }) = _<Name>State;
}

/////////////////
// ROUTE STATE //
/////////////////
@freezed
abstract class <Name>RouteState with _$<Name>RouteState {
  const factory <Name>RouteState({
    @Default(0) int count,
  }) = _<Name>RouteState;
}

/////////////////
//// ACTION /////
/////////////////
sealed class <Name>Action {
  const <Name>Action();
}

class <Name>ActionIncrement extends <Name>Action {
  const <Name>ActionIncrement();
}

class <Name>ActionDecrement extends <Name>Action {
  const <Name>ActionDecrement();
}

/////////////////
// ENVIRONMENT //
/////////////////
class <Name>Environment {
  const <Name>Environment();
}
```

### `lib/routes/<name>/<name>.core.dart` — With dart_mappable

```dart
part of '<name>.dart';

/////////////////
///// STATE /////
/////////////////
@MappableClass()
class <Name>State with <Name>StateMappable {
  final int count;

  const <Name>State({this.count = 0});
}

/////////////////
// ROUTE STATE //
/////////////////
@MappableClass()
class <Name>RouteState with <Name>RouteStateMappable {
  final int count;

  const <Name>RouteState({this.count = 0});
}

/////////////////
//// ACTION /////
/////////////////
sealed class <Name>Action {
  const <Name>Action();
}

class <Name>ActionIncrement extends <Name>Action {
  const <Name>ActionIncrement();
}

class <Name>ActionDecrement extends <Name>Action {
  const <Name>ActionDecrement();
}

/////////////////
// ENVIRONMENT //
/////////////////
class <Name>Environment {
  const <Name>Environment();
}
```

### `lib/routes/<name>/<name>.route.dart`

This file contains the `Routable` subclass with `routeLens`, `actionPrism`, the local reducer, and all required overrides:

```dart
part of '<name>.dart';

class <Name>Route
    extends
        Routable<
          AppState,
          <Name>RouteState,
          <Name>State,
          AppAction,
          <Name>Action,
          AppEnvironment,
          <Name>Environment
        > {

  // Lens: maps (AppState, RouteState) <-> local State
  RouteLens<AppState, <Name>RouteState, <Name>State?> get routeLens => (
    get: (appState, routeState) => buildLocalState(appState, routeState),
    set: (appState, routeState, localState) => localState == null
        ? (appState, routeState)
        : setBackFromLocalState(appState, routeState, localState),
  );

  // Prism: maps AppAction <-> (RouteID, local Action)
  Prism<AppAction, <Name>Action, RouteID> get actionPrism => (
    extract: (globalAction) => extractAction(globalAction),
    embed: (routeID, localAction) => toAppAction(routeID, localAction),
  );

  @override
  Widget build(
    BuildContext context,
    Store<<Name>State, <Name>Action> store,
    NestedNavigator<AppState, AppAction> nestedNavigator,
  ) => <Name>Page(store: store, nestedNavigator: nestedNavigator);

  @override
  <Name>Environment buildLocalEnvironment(AppEnvironment env) =>
      const <Name>Environment();

  @override
  <Name>State buildLocalState(
    AppState appState,
    <Name>RouteState routeState,
  ) => <Name>State(count: routeState.count);

  @override
  (RouteID, <Name>Action)? extractAction(AppAction action) =>
      action is AppAction<Name> ? (action.id, action.action) : null;

  @override
  RouteID id(<Name>RouteState routeState) => '<name>';

  @override
  Reducer<AppState, AppAction, AppEnvironment> reducer() =>
      localReducer.pullbackRoute(
        routerStateLens: AppStateLens.navigation,
        routeLens: routeLens,
        actionPrism: actionPrism,
        toLocalEnvironment: buildLocalEnvironment,
      );

  @override
  (AppState, <Name>RouteState) setBackFromLocalState(
    AppState appState,
    <Name>RouteState routeState,
    <Name>State localState,
  ) => (appState, routeState.copyWith(count: localState.count));

  @override
  AppAction toAppAction(RouteID id, <Name>Action action) =>
      AppAction.<name>(id, action);

  static final localReducer =
      Reducer<<Name>State, <Name>Action, <Name>Environment>(
        reduce: (state, action, environment) => switch (action) {
          <Name>ActionIncrement() => (
            state: state.copyWith(count: state.count + 1),
            effect: const Effect.none(),
          ),
          <Name>ActionDecrement() => (
            state: state.copyWith(count: state.count - 1),
            effect: const Effect.none(),
          ),
        },
      );
}
```

Key elements:
- **`routeLens`** — converts between `(AppState, RouteState)` and local `State`. Used by `pullbackRoute` to scope the reducer.
- **`actionPrism`** — converts between `AppAction` and `(RouteID, LocalAction)`. Used by `pullbackRoute` to scope actions.
- **`reducer()`** — calls `localReducer.pullbackRoute(...)` with the lenses and prism, NOT returning the `localReducer` directly.
- **`localReducer`** — a `static final` containing the actual state/action reduction logic.

### `lib/routes/<name>/<name>.page.dart`

```dart
part of '<name>.dart';

class <Name>Page extends StatelessWidget {
  final Store<<Name>State, <Name>Action> store;
  final NestedNavigator<AppState, AppAction> nestedNavigator;

  const <Name>Page({
    super.key,
    required this.store,
    required this.nestedNavigator,
  });

  @override
  Widget build(BuildContext context) {
    return WithStore<<Name>State, <Name>Action>(
      store: store,
      builder: (state, send, context) => Scaffold(
        appBar: AppBar(title: const Text('<Name>')),
        body: Center(
          child: Text(
            '${state.count}',
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: () => send(const <Name>ActionIncrement()),
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: () => send(const <Name>ActionDecrement()),
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Presentation Variants

### `--sheet` (Bottom Sheet)

In the page's `build` method, the `Routable` is the same. The difference is in the binding — use `.sheet()` instead of `.page()`:

```dart
ComposableRouteBinding.match(
  '/parent/<name>',
  (state, location, params) => [
    ParentRoute().page(state.navigation, defaultRouteState: ParentRouteState()),
    <Name>Route().sheet(
      state.navigation,
      defaultRouteState: <Name>RouteState(),
      options: SheetOptions(
        showDragHandle: true,
        enableDrag: true,
        constraints: const BoxConstraints(maxHeight: 500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
  ],
  onPop: (appState, location, params) =>
      const OnPopResult.redirect('/parent'),
),
```

### `--dialog` (Dialog)

```dart
<Name>Route().dialog(
  state.navigation,
  defaultRouteState: <Name>RouteState(),
  options: DialogOptions(barrierDismissible: true),
),
```

### Cupertino Variants

```dart
<Name>Route().cupertinoPage(state.navigation, defaultRouteState: <Name>RouteState());
<Name>Route().cupertinoSheet(state.navigation, defaultRouteState: <Name>RouteState());
<Name>Route().cupertinoDialog(state.navigation, defaultRouteState: <Name>RouteState());
```

### `--tabs` (Tab Navigation)

```dart
<Name>Route().tabs(
  state.navigation,
  [
    [TabA().page(state.navigation, defaultRouteState: TabARouteState())],
    [TabB().page(state.navigation, defaultRouteState: TabBRouteState())],
    [TabC().page(state.navigation, defaultRouteState: TabCRouteState())],
  ],
  currentTab: 0,
  defaultRouteState: <Name>RouteState(),
),
```

## Pop Behavior

```dart
ComposableRouteBinding.match(
  '/<name>',
  (state, location, params) => [/* ... */],
  onPop: (appState, location, params) =>
      const OnPopResult.redirect('/'),
      // OnPopResult.prevent()   — block pop
      // OnPopResult.system()    — default behavior
),
```

## App Integration Steps

**IMPORTANT:** Every new route requires ALL of the following steps. Missing any step will cause the route to silently not work.

### 1. Add action variant to `AppAction` in `app.action.dart`

**Without code generation:**

```dart
sealed class AppAction {
  const AppAction();
  const factory AppAction.navigation(RouterAction<AppState, AppAction> action) =
      AppActionNavigation;
  const factory AppAction.<name>(RouteID id, <Name>Action action) =
      AppAction<Name>;  // <-- ADD
}

class AppAction<Name> extends AppAction {
  final RouteID id;
  final <Name>Action action;
  const AppAction<Name>(this.id, this.action);
}
```

**With freezed:**

```dart
@freezed
abstract class AppAction with _$AppAction {
  const factory AppAction.navigation(RouterAction<AppState, AppAction> action) =
      AppActionNavigation;
  const factory AppAction.<name>(RouteID id, <Name>Action action) =
      AppAction<Name>;  // <-- ADD
}
```

### 2. Register `<Name>Route()` in `appReducer`'s `.navigator(routes: [...])`

This is critical — without it, the route's reducer will never run:

```dart
// In app.reducer.dart
final Reducer<AppState, AppAction, AppEnvironment> appReducer =
    Reducer<AppState, AppAction, AppEnvironment>(
      reduce: (state, action, environment) =>
          (state: state, effect: const Effect.none()),
    ).navigator(
      routerStateLens: AppStateLens.navigation,
      routerActionLens: AppActionLens.navigation,
      toNavigatorEnvironment: (env) => env.navigator,
      routes: [
        // ... existing routes
        <Name>Route(),  // <-- ADD HERE
      ],
    );
```

### 3. Add binding to `app.bindings.dart`

```dart
final bindings = <ComposableRouteBinding<AppState, AppAction>>[
  // ... existing bindings
  ComposableRouteBinding.matchOne(
    '/<name>',
    (state, location, params) => <Name>Route().page(
      state.navigation,
      defaultRouteState: <Name>RouteState(),
    ),
  ),
];
```

### 4. Handle cross-feature navigation in parent reducer (if needed)

If the route needs to trigger navigation or cross-feature effects, add a case in the parent reducer's `reduce` function (before `.navigator()`):

```dart
case AppAction<Name> action:
  switch (action.action) {
    case <Name>ActionNavigate _:
      return (
        state: state,
        effect: Effect.value(
          AppAction.navigation(RouterAction.navigate('/other')),
        ),
      );
    default:
      break;
  }
```

### 5. Add environment to `AppEnvironment` (if the route has dependencies)

```dart
class AppEnvironment {
  final RouterEnvironment<AppState, AppAction> navigator;
  final <Name>Environment <name>;  // <-- ADD

  const AppEnvironment._({
    required this.navigator,
    required this.<name>,  // <-- ADD
  });

  factory AppEnvironment.withDependencies({
    required RouterEnvironment<AppState, AppAction> navigator,
  }) => AppEnvironment._(
    navigator: navigator,
    <name>: const <Name>Environment(),  // <-- ADD
  );
}
```

Then update `buildLocalEnvironment` in the route:

```dart
@override
<Name>Environment buildLocalEnvironment(AppEnvironment env) => env.<name>;
```

## Checklist

- [ ] Checked `pubspec.yaml` for freezed / dart_mappable
- [ ] Route folder created at `lib/routes/<name>/`
- [ ] `<name>.dart` barrel file with imports and part directives
- [ ] `<name>.core.dart` with State, RouteState, Action, Environment (using correct data class strategy)
- [ ] `<name>.route.dart` with `Routable` subclass including `routeLens`, `actionPrism`, and `localReducer.pullbackRoute()`
- [ ] `<name>.page.dart` with widget using `WithStore`
- [ ] **Action variant added to `AppAction`** in `app.action.dart`
- [ ] **Route registered in `appReducer`'s `.navigator(routes: [...])`** — without this the route won't work
- [ ] `ComposableRouteBinding` added to `app.bindings.dart`
- [ ] Cross-feature navigation handled in parent reducer if needed
- [ ] Environment added to `AppEnvironment` if the route has dependencies
- [ ] Barrel file import added (e.g., `import 'package:<app>/routes/<name>/<name>.dart';`) in `app.dart`
- [ ] If code generation used: `build_runner build` executed
