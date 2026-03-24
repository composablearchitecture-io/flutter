---
name: init-project
description: Initialize a new Flutter project with Composable Architecture and composable_architecture_router. Scaffolds app state, actions, reducer, environment, page, router bindings, and main.dart. Optionally uses freezed or dart_mappable for code generation.
argument-hint: <app-name> [--freezed] [--dart-mappable]
---

# Init Project

Scaffold a complete Flutter application using the Composable Architecture pattern with `composable_architecture_router` for Navigator 2.0 routing. This creates the full app shell — state, actions, reducer, environment, router bindings, rules, and the entry point.

**Before generating**, ask the user:
> Would you like to use a **data class library** for state classes?
> - **freezed** — generates `copyWith`, `==`, `hashCode` via `@freezed` annotations
> - **dart_mappable** — generates `copyWith`, `==`, `hashCode` via `@MappableClass()` annotations
> - **Neither** — hand-written `copyWith`, `operator ==`, and `hashCode`

## Prerequisites

The user must have a Flutter project created (via `flutter create`). If not, create one first:

```bash
flutter create <app_name>
cd <app_name>
```

## Dependencies

### Without code generation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  composable_architecture_flutterw: ^0.1.0
  composable_architecture_router: ^0.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### With `--freezed`

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  composable_architecture_flutterw: ^0.1.0
  composable_architecture_router: ^0.1.0
  freezed_annotation: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  freezed: ^3.0.0
  build_runner: ^2.4.0
```

### With `--dart-mappable`

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  composable_architecture_flutterw: ^0.1.0
  composable_architecture_router: ^0.1.0
  dart_mappable: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  dart_mappable_builder: ^4.0.0
  build_runner: ^2.4.0
```

## Project Structure

Create the following file structure:

```
lib/
├── main.dart
└── app/
    ├── app.dart              # Barrel file with imports and part directives
    ├── app.state.dart        # AppState class
    ├── app.action.dart       # AppAction sealed class
    ├── app.reducer.dart      # appReducer
    ├── app.environment.dart  # AppEnvironment with router dependency
    ├── app.page.dart         # App widget (entry point widget)
    ├── app.bindings.dart     # Route bindings list
    └── app.rule.dart         # Route rules list
```

## File Contents

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:<app_name>/app/app.dart';

void main() {
  runApp(const App());
}
```

### `lib/app/app.dart` (Barrel File)

```dart
import 'package:composable_architecture_flutterw/material.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';
import 'package:flutter/material.dart';

part 'app.action.dart';

part 'app.environment.dart';

part 'app.page.dart';

part 'app.reducer.dart';

part 'app.bindings.dart';

part 'app.rule.dart';

part 'app.state.dart';
```

If using `--freezed`, also add:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app.freezed.dart';
```

If using `--dart-mappable`, also add:

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'app.mapper.dart';
```

### `lib/app/app.state.dart` — Without code generation

```dart
part of 'app.dart';

class AppState {
  final MaterialAppState materialAppState;
  final RouterState<AppState, AppAction> navigation;

  const AppState({required this.materialAppState, required this.navigation});

  static AppState initial() {
    return AppState(
      materialAppState: MaterialAppState.initial(),
      navigation: RouterState.initial(),
    );
  }

  AppState copyWith({
    MaterialAppState? materialAppState,
    RouterState<AppState, AppAction>? navigation,
  }) {
    return AppState(
      materialAppState: materialAppState ?? this.materialAppState,
      navigation: navigation ?? this.navigation,
    );
  }

  bool isEqual(AppState other) {
    return materialAppState == other.materialAppState &&
        navigation == other.navigation;
  }
}
```

### `lib/app/app.state.dart` — With `--freezed`

```dart
part of 'app.dart';

@freezed
abstract class AppState with _$AppState {
  const factory AppState({
    required MaterialAppState materialAppState,
    required RouterState<AppState, AppAction> navigation,
  }) = _AppState;

  static AppState initial() {
    return AppState(
      materialAppState: MaterialAppState.initial(),
      navigation: RouterState.initial(),
    );
  }
}
```

### `lib/app/app.state.dart` — With `--dart-mappable`

```dart
part of 'app.dart';

@MappableClass()
class AppState with AppStateMappable {
  final MaterialAppState materialAppState;
  final RouterState<AppState, AppAction> navigation;

  const AppState({required this.materialAppState, required this.navigation});

  static AppState initial() {
    return AppState(
      materialAppState: MaterialAppState.initial(),
      navigation: RouterState.initial(),
    );
  }
}
```

### `lib/app/app.action.dart` — Without code generation

```dart
part of 'app.dart';

sealed class AppAction {
  const AppAction();
  const factory AppAction.navigation(RouterAction<AppState, AppAction> action) =
      AppActionNavigation;
}

class AppActionNavigation extends AppAction {
  final RouterAction<AppState, AppAction> action;

  const AppActionNavigation(this.action);
}
```

### `lib/app/app.action.dart` — With `--freezed`

```dart
part of 'app.dart';

@freezed
abstract class AppAction with _$AppAction {
  const factory AppAction.navigation(RouterAction<AppState, AppAction> action) =
      AppActionNavigation;
}
```

### `lib/app/app.reducer.dart`

```dart
part of 'app.dart';

class AppStateLens {
  static Lens<AppState, RouterState<AppState, AppAction>> navigation = (
    get: (state) => state.navigation,
    set: (state, navigation) => state.copyWith(navigation: navigation),
  );
}

class AppActionLens {
  static ActionLens<AppAction, RouterAction<AppState, AppAction>> navigation = (
    extract: (action) => action is AppActionNavigation ? action.action : null,
    embed: (value) => AppAction.navigation(value),
  );
}

final Reducer<AppState, AppAction, AppEnvironment> appReducer =
    Reducer<AppState, AppAction, AppEnvironment>(
      reduce: (state, action, environment) =>
          (state: state, effect: const Effect.none()),
    ).navigator(
      routerStateLens: AppStateLens.navigation,
      routerActionLens: AppActionLens.navigation,
      toNavigatorEnvironment: (env) => env.navigator,
      routes: [
        // Register Routable instances here as routes are added
      ],
    );
```

The `.navigator()` call at the end is critical — it wires the router's state management into the reducer. Every `Routable` subclass must be registered in the `routes` list for its reducer to be invoked and its state to be managed by the navigation system.

### `lib/app/app.environment.dart`

```dart
part of 'app.dart';

class AppEnvironment {
  final RouterEnvironment<AppState, AppAction> navigator;

  const AppEnvironment._({required this.navigator});

  factory AppEnvironment.withDependencies({
    required RouterEnvironment<AppState, AppAction> navigator,
  }) => AppEnvironment._(navigator: navigator);
}
```

### `lib/app/app.page.dart`

```dart
part of 'app.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencyProvider =
        DependencyProvider<AppState, AppAction, AppEnvironment>(
          storeBuilder: (env) =>
              Store.initial<AppState, AppAction, AppEnvironment>(
                AppState.initial(),
                appReducer,
                env,
              ),
          environmentBuilder: (provider) => AppEnvironment.withDependencies(
            navigator: RouterEnvironment(
              store: () => provider.store,
              bindings: bindings,
              rules: rules,
            ),
          ),
        );

    return Dependency(
      dependencyProvider: dependencyProvider,
      child: Builder(
        builder: (context) => ComposableMaterialApp(
          title: "<App Title>",
          store: dependencyProvider.store,
          toMaterialAppState: (appState) => appState.materialAppState,
          routerConfig: ComposableRouter(
            store: dependencyProvider.store,
            toRouterState: (state) => state.navigation,
            toAppAction: AppAction.navigation,
            environment: dependencyProvider.environment.navigator,
          ),
        ),
      ),
    );
  }
}
```

Replace `<App Title>` with the user's app name (title-cased).

### `lib/app/app.bindings.dart`

```dart
part of 'app.dart';

final bindings = <ComposableRouteBinding<AppState, AppAction>>[];
```

### `lib/app/app.rule.dart`

```dart
part of 'app.dart';

final rules = <ComposableRouteRule<AppState, AppAction>>[];
```

## Post-Generation Steps

### Without code generation

No additional steps. Run `flutter run` to verify.

### With `--freezed` or `--dart-mappable`

Run the build runner to generate files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `app.freezed.dart` or `app.mapper.dart` with `copyWith`, `==`, `hashCode`, and `toString`.

## Conventions

1. The `App` widget is the root — it creates the `DependencyProvider`, `Store`, and `ComposableRouter`
2. `main.dart` only calls `runApp(const App())`
3. All app-level files use `part`/`part of` with `app.dart` as the barrel
4. `bindings` and `rules` start as empty lists — populate them as routes are added (use the `create-route` skill)
5. `AppEnvironment` holds the `RouterEnvironment` and any global dependencies
6. The reducer ends with `.navigator()` which wires router state/action lenses and registers all `Routable` routes — compose child reducers before `.navigator()` as features are added (use the `create-feature` and `create-reducer` skills)
7. `AppState` always includes `MaterialAppState` and `RouterState<AppState, AppAction>`
8. `AppAction` always includes a `navigation` variant wrapping `RouterAction<AppState, AppAction>`

## When using freezed

1. Add `import 'package:freezed_annotation/freezed_annotation.dart';` to the barrel file
2. Add `part 'app.freezed.dart';` to the barrel file
3. Use `@freezed` annotation on state classes — classes must be declared `abstract` (e.g., `abstract class AppState with _$AppState`)
4. State uses `const factory` constructors — freezed generates `copyWith`, `==`, `hashCode`
5. The `initial()` factory remains a static method (not generated by freezed)
6. Do NOT hand-write `copyWith`, `==`, or `hashCode` — freezed handles these
7. Run `dart run build_runner build --delete-conflicting-outputs` after any change to freezed-annotated classes

## When using dart_mappable

1. Add `import 'package:dart_mappable/dart_mappable.dart';` to the barrel file
2. Add `part 'app.mapper.dart';` to the barrel file
3. Use `@MappableClass()` annotation on state classes
4. Add the generated mixin (e.g., `with AppStateMappable`) to the class
5. Keep the manual constructor — dart_mappable generates `copyWith`, `==`, `hashCode`
6. The `initial()` factory remains a static method
7. Do NOT hand-write `copyWith`, `==`, or `hashCode` — dart_mappable handles these
8. Run `dart run build_runner build --delete-conflicting-outputs` after any change to annotated classes

## Checklist

- [ ] Asked user about data class library preference (freezed / dart_mappable / neither)
- [ ] `pubspec.yaml` updated with correct dependencies
- [ ] `lib/main.dart` created with `runApp(const App())`
- [ ] `lib/app/app.dart` barrel file with all `part` directives
- [ ] `lib/app/app.state.dart` with `AppState`, `initial()`, and working `==`/`hashCode`/`copyWith`
- [ ] `lib/app/app.action.dart` with sealed `AppAction` and `navigation` variant
- [ ] `lib/app/app.reducer.dart` with `AppStateLens`, `AppActionLens`, and `appReducer` ending in `.navigator()`
- [ ] `lib/app/app.environment.dart` with `AppEnvironment` holding `RouterEnvironment`
- [ ] `lib/app/app.page.dart` with `App` widget, `DependencyProvider`, `ComposableMaterialApp`, and `ComposableRouter`
- [ ] `lib/app/app.bindings.dart` with empty bindings list
- [ ] `lib/app/app.rule.dart` with empty rules list
- [ ] If code generation: annotations, generated `part` file, and `build_runner` executed
- [ ] App compiles and runs with `flutter run`
