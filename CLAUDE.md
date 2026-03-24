# CLAUDE.md

## Project Overview

This is a monorepo (managed by Melos) implementing the Composable Architecture pattern for Dart/Flutter. It consists of three packages:

- **composable_architecture_core** - Pure Dart core (Store, Reducer, Effect, Lens, Observable)
- **composable_architecture_flutterw** - Flutter widget bindings (WithStore, ForEachStore, IfLetStore, SwitchStore)
- **composable_architecture_router** - Navigator 2.0 integration

## Build & Test

```bash
melos bootstrap          # install dependencies
melos run test           # run all tests
melos run format         # format code
melos run fix            # apply dart fixes
```

To test a single package:
```bash
cd packages/composable_architecture_core && dart test
cd packages/composable_architecture_flutterw && flutter test
```

## Architecture

- **Unidirectional data flow:** Action -> Reducer -> (State, Effect)
- **Composition via pullback:** local reducers are lifted to global scope using Lens/ActionLens/Prism
- **Effects are values:** sealed class hierarchy describing work (futures, streams, cancellation, debounce, throttle)
- **Store scoping:** parent stores create child stores via `scope()` with state/action projections
- **Observable:** lightweight reactive primitive (not Streams) with `map`, `distinct`, `when` operators

## Key Patterns

- State classes use manual `copyWith`, `==`, and `hashCode` (no code generation)
- Actions use `sealed class` or `enum` for exhaustive pattern matching
- Reducers are composed with `Reducer.combine([...])` and scoped with `.pullback()`
- Collection state uses `forEach` with `Lens` + `Prism` for per-element reduction
- Flutter widgets rebuild via `CurrentValueSubject` listeners, not Streams

## File Conventions

- Feature modules use `part`/`part of` with a barrel `.dart` file
- Store files: `feature.store.dart` (state, action, reducer)
- Page files: `feature.page.dart` (widget)
- No code generation - all code is hand-written

## Dependencies

- composable_architecture_core: zero external dependencies
- composable_architecture_flutterw: depends only on Flutter SDK + composable_architecture_core
- composable_architecture_router: depends on composable_architecture_flutterw
