---
name: add-effect
description: Add side effects to a Composable Architecture reducer — async tasks, streams, cancellation, debounce, throttle. Use when adding API calls, timers, or async work with composable_architecture_core.
argument-hint: <effect-type>
---

# Add Effect

Add side effects to a reducer using the `composable_architecture_core` package. Effects are values — a sealed class hierarchy describing async work. They are always returned from reducers, never performed directly.

## Prerequisites

```yaml
dependencies:
  composable_architecture_core: ^0.1.0
```

## Conventions

1. Effects are returned from reducers as part of `(state:, effect:)` records
2. Never perform side effects directly in reducers — always return an `Effect`
3. Use `.cancellable()` for long-running effects that should be cancellable
4. Use `const Effect.none()` when no effect is needed (note the `const`)
5. State classes used in effect returns must have working `copyWith` — via freezed, dart_mappable, or hand-written (check `pubspec.yaml`)

## Effect Catalog

### No Effect
```dart
return (state: state, effect: const Effect.none());
```

### Synchronous Action Dispatch
```dart
return (state: state, effect: const Effect.value(MyAction.doSomething()));
// Non-const:
return (state: state, effect: Effect.value(MyAction.loaded(data)));
```

### Async Task (returns an action)
```dart
return (
  state: state.copyWith(isLoading: true),
  effect: Effect<MyAction>.task(() async {
    final data = await env.apiClient.fetchData();
    return MyAction.dataLoaded(data);
  }),
);
```

### Fire and Forget (no action returned)
```dart
return (
  state: state,
  effect: Effect<MyAction>.fireAndForget(() {
    env.analytics.track('button_pressed');
  }),
);
```

### Run with Send (fire-and-forget with optional sends)
```dart
return (
  state: state,
  effect: Effect<MyAction>.run((send) async {
    await env.cache.clear();
    send(MyAction.cacheCleared());
  }),
);
```

### Cancellable Effect
```dart
return (
  state: state,
  effect: Effect<MyAction>.task(() async {
    final results = await env.search(query);
    return MyAction.searchResults(results);
  }).cancellable('search-request'),
);
```

### Cancel a Running Effect
```dart
return (state: state, effect: Effect.cancel('search-request'));
```

### Delayed Effect
```dart
return (
  state: state,
  effect: Effect.value(MyAction.timeout())
      .delay(const Duration(seconds: 30)),
);
```

### Debounced Effect (cancel + delay)
```dart
return (
  state: state.copyWith(query: action.query),
  effect: Effect<MyAction>.task(() async {
    final results = await env.search(action.query);
    return MyAction.searchResults(results);
  })
      .delay(const Duration(milliseconds: 300))
      .cancellable('search-debounce'),
);
```

### Stream (continuous values)
```dart
return (
  state: state,
  effect: Effect<MyAction>.stream(
    () => env.locationService.updates
        .map((loc) => MyAction.locationUpdated(loc)),
  ).cancellable('location-stream'),
);
```

### Periodic Effect
```dart
return (
  state: state,
  effect: Effect<MyAction>.periodic(
    const Duration(seconds: 5),
    (count) => MyAction.tick(count),
  ).cancellable('timer'),
);
```

### Merge Effects (parallel)
```dart
return (
  state: state,
  effect: Effect.merge([
    Effect.task(() async {
      final user = await env.fetchUser();
      return MyAction.userLoaded(user);
    }),
    Effect.task(() async {
      final prefs = await env.fetchPreferences();
      return MyAction.prefsLoaded(prefs);
    }),
  ]),
);
```

### Concatenate Effects (sequential)
```dart
return (
  state: state,
  effect: Effect.concatenate([
    Effect.value(MyAction.startSync()),
    Effect.task(() async {
      await env.syncData();
      return MyAction.syncComplete();
    }),
  ]),
);
```

### Map (transform the action type)
```dart
final childEffect = Effect.task(() async {
  final data = await env.fetch();
  return ChildAction.loaded(data);
});

return (
  state: state,
  effect: childEffect.map((childAction) => MyAction.child(childAction)),
);
```

### FlatMap (chain effects)
```dart
return (
  state: state,
  effect: Effect<MyAction>.task(() async {
    final token = await env.authenticate();
    return MyAction.authenticated(token);
  }).flatMap((action) {
    if (action is MyActionAuthenticated) {
      return Effect.task(() async {
        final data = await env.fetchWithToken(action.token);
        return MyAction.dataLoaded(data);
      });
    }
    return Effect.value(action);
  }),
);
```

## Common Recipes

### Loading → Success / Error

```dart
case MyActionFetch _:
  return (
    state: state.copyWith(isLoading: true, error: null),
    effect: Effect<MyAction>.task(() async {
      try {
        final data = await env.api.fetch();
        return MyAction.fetchSuccess(data);
      } catch (e) {
        return MyAction.fetchError(e.toString());
      }
    }),
  );

case MyActionFetchSuccess action:
  return (
    state: state.copyWith(isLoading: false, data: action.data),
    effect: const Effect.none(),
  );

case MyActionFetchError action:
  return (
    state: state.copyWith(isLoading: false, error: action.message),
    effect: const Effect.none(),
  );
```

### Search with Debounce

```dart
case MyActionSearchChanged action:
  return (
    state: state.copyWith(query: action.query),
    effect: Effect<MyAction>.task(() async {
      final results = await env.search(action.query);
      return MyAction.searchResults(results);
    })
        .delay(const Duration(milliseconds: 300))
        .cancellable('search'),
  );
```

### Start / Stop a Subscription

```dart
case MyActionStartListening _:
  return (
    state: state,
    effect: Effect<MyAction>.stream(
      () => env.messages.map((m) => MyAction.received(m)),
    ).cancellable('messages'),
  );

case MyActionStopListening _:
  return (state: state, effect: Effect.cancel('messages'));
```

### Throttle (periodic sampling)

```dart
case MyActionStartPolling _:
  return (
    state: state,
    effect: Effect<MyAction>.periodic(
      const Duration(seconds: 10),
      (_) => MyAction.pollNow(),
    ).cancellable('polling'),
  );

case MyActionStopPolling _:
  return (state: state, effect: Effect.cancel('polling'));
```
