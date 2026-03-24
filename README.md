# Flutter Composable Architecture

A Dart/Flutter implementation of the [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) pattern. Build applications with unidirectional data flow, composable reducers, structured side effects, and first-class testability.

## Packages

| Package | Description |
|---|---|
| [composable_architecture_core](packages/composable_architecture_core/) | Pure Dart core - Store, Reducer, Effect, Lens, Observable. No Flutter dependency. |
| [composable_architecture_flutterw](packages/composable_architecture_flutterw/) | Flutter widgets - WithStore, ForEachStore, IfLetStore, SwitchStore, app builders. |
| [composable_architecture_router](packages/composable_architecture_router/) | Navigator 2.0 integration built on the composable architecture. |

## Architecture

```
Action  ──>  Reducer(State, Action, Env)  ──>  (NewState, Effect)
  ^                                                  |
  |                                                  v
  └──────────────  Effect emits actions  ────────────┘
```

**Store** holds state, processes actions through a **Reducer**, and executes **Effects**.
**Reducers** compose via `combine`, `pullback`, and `forEach`.
**Effects** compose via `map`, `merge`, `concatenate`, `debounce`, `throttle`, and cancellation.
**Lenses** and **Prisms** enable modular state/action decomposition.

## Quick Start

```dart
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';

// 1. Define actions
enum CounterAction { increment, decrement }

// 2. Define reducer
final counterReducer = Reducer<int, CounterAction, EmptyEnvironment>.transform(
  (state, action, env) => switch (action) {
    CounterAction.increment => state + 1,
    CounterAction.decrement => state - 1,
  },
);

// 3. Create store
final store = Store.emptyEnvironment(0, counterReducer);

// 4. Build UI
WithStore<int, CounterAction>(
  store: store,
  builder: (count, send, context) => Text('$count'),
);
```

## Development

This monorepo uses [Melos](https://melos.invertase.dev/) for workspace management.

```bash
# Install melos
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run tests across all packages
melos run test

# Format code
melos run format

# Apply dart fixes
melos run fix
```

## Requirements

- Dart SDK >= 3.0.6
- Flutter SDK >= 3.0.0

## License

See [LICENSE](LICENSE) for details.
