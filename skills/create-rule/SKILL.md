---
name: create-rule
description: Create route rules (guards) for composable_architecture_router — authentication guards, forced redirects, deep link rewrites, and conditional access control.
argument-hint: <rule-description> [--guard-all] [--guard-on]
---

# Create Rule

Define route rules (guards) that control access to routes using `ComposableRouteRule` from `composable_architecture_router`. Rules are evaluated **before** bindings — they can allow, deny (redirect), or force-allow navigation to a given path.

## Prerequisites

```yaml
dependencies:
  composable_architecture_router: ^0.1.0
```

## Conventions

1. Rules are defined in `app.rule.dart` as a `List<ComposableRouteRule<AppState, AppAction>>`
2. Rules are evaluated in order — first deny or force-allow wins
3. If all rules return `allow`, the binding is resolved normally
4. Public route constants should be collected in a list for reuse across exclusion sets
5. Rules should be stateless — they only read `AppState` and the current `Uri`/path parameters
6. Rules are registered in the `RouterEnvironment` via the `rules` parameter

## Rule Constructors

### `guardAll` — Guard every path except exclusions

Use when most routes require a condition (e.g., authentication) and only a few are public:

```dart
ComposableRouteRule<AppState, AppAction>.guardAll(
  excludedPaths: ['/splash', '/sign-in', '/onboarding'],
  handler: (appState, location, pathParameters) {
    if (appState.user == null) {
      return const RouteRuleResult<AppState, AppAction>.deny('/sign-in');
    }
    return const RouteRuleResult<AppState, AppAction>.allow();
  },
),
```

### `guardOn` — Guard specific paths only

Use when only certain routes need protection or rewriting:

```dart
ComposableRouteRule<AppState, AppAction>.guardOn(
  includedPaths: ['/admin', '/admin/settings'],
  handler: (appState, location, pathParameters) {
    if (!appState.isAdmin) {
      return const RouteRuleResult<AppState, AppAction>.deny('/');
    }
    return const RouteRuleResult<AppState, AppAction>.allow();
  },
),
```

### `guardWhen` — Custom matching logic

Use when path matching needs to be dynamic or regex-based:

```dart
ComposableRouteRule<AppState, AppAction>.guardWhen(
  bindsTo: (location, allPaths) {
    if (location.path.startsWith('/admin')) return {};
    return null; // null = does not match
  },
  handler: (appState, location, pathParameters) {
    if (!appState.isAdmin) {
      return const RouteRuleResult<AppState, AppAction>.deny('/');
    }
    return const RouteRuleResult<AppState, AppAction>.allow();
  },
),
```

## Rule Results

- `RouteRuleResult.allow()` — proceed to the next rule (or resolve binding if last)
- `RouteRuleResult.deny('/redirect-path')` — redirect to another path, skip binding resolution
- `RouteRuleResult.forceAllow()` — proceed and skip all remaining rules

## Common Patterns

### Public routes list

Collect public (unauthenticated) routes in a constant for reuse:

```dart
part of 'app.dart';

const publicRoutes = [
  Routes.splash,
  Routes.onboarding,
  Routes.signIn,
  Routes.signUp,
  Routes.forcedUpdate,
];

final rules = <ComposableRouteRule<AppState, AppAction>>[
  // ...
];
```

### Loading/splash guard

Redirect to splash if the app hasn't finished loading, except for the splash and onboarding screens:

```dart
ComposableRouteRule<AppState, AppAction>.guardAll(
  excludedPaths: [Routes.splash, Routes.onboarding],
  handler: (appState, location, pathParameters) {
    if (appState.shouldLoad) {
      return RouteRuleResult<AppState, AppAction>.deny(
        '${Routes.splash}?returnTo=${const Base64Encoder.urlSafe().convert(location.toString().codeUnits)}',
      );
    }
    return const RouteRuleResult<AppState, AppAction>.allow();
  },
),
```

The `returnTo` query parameter encodes the original destination so the splash screen can redirect back after loading.

### Forced update guard

Block all routes (except splash and the update screen itself) when the app needs a mandatory update:

```dart
ComposableRouteRule<AppState, AppAction>.guardAll(
  excludedPaths: [Routes.splash, Routes.forcedUpdate],
  handler: (appState, location, pathParameters) {
    if (appState.shouldUpdate) {
      return const RouteRuleResult<AppState, AppAction>.deny(Routes.forcedUpdate);
    }
    return const RouteRuleResult<AppState, AppAction>.allow();
  },
),
```

### Authentication guard

Redirect unauthenticated users to sign-in for all non-public routes:

```dart
ComposableRouteRule<AppState, AppAction>.guardAll(
  excludedPaths: publicRoutes,
  handler: (appState, location, pathParameters) {
    if (appState.user == null) {
      return const RouteRuleResult<AppState, AppAction>.deny(Routes.signIn);
    }
    return const RouteRuleResult<AppState, AppAction>.allow();
  },
),
```

### Deep link rewrite

Rewrite incoming deep links to internal routes (e.g., a share URL to the app's loader):

```dart
ComposableRouteRule<AppState, AppAction>.guardOn(
  includedPaths: ['/recipe/share/:id'],
  handler: (appState, location, pathParameters) {
    final recipeId = pathParameters['id']!;
    return RouteRuleResult<AppState, AppAction>.deny('/recipe-loader?id=$recipeId');
  },
),
```

### External URL handler

Open certain paths in an external browser instead of the app:

```dart
ComposableRouteRule<AppState, AppAction>.guardOn(
  includedPaths: ['/recipe/print/:id'],
  handler: (appState, location, pathParameters) {
    final recipeId = pathParameters['id']!;
    final baseUrl = Uri.parse(initialConfig.baseUrl);
    final resolved = location.replace(
      host: baseUrl.host,
      scheme: baseUrl.scheme,
      port: baseUrl.port,
    );
    launchUrl(resolved, mode: LaunchMode.inAppBrowserView);
    return RouteRuleResult<AppState, AppAction>.deny('/collection/$allRecipeCookbookId/$recipeId');
  },
),
```

### Subscription guard

Guard routes that require a subscription or quota:

```dart
ComposableRouteRule<AppState, AppAction>.guardOn(
  includedPaths: ['/recipe-loader'],
  handler: (appState, location, pathParameters) {
    if (appState.importInfo?.freeImports == 0 && !appState.isSubscribed) {
      return const RouteRuleResult<AppState, AppAction>.deny('/subscription');
    }
    return const RouteRuleResult<AppState, AppAction>.allow();
  },
),
```

### Path alias/redirect

Redirect a legacy or shorthand path to its canonical form:

```dart
ComposableRouteRule<AppState, AppAction>.guardOn(
  includedPaths: ['/recipe/:id'],
  handler: (appState, location, pathParameters) {
    final recipeId = pathParameters['id']!;
    return RouteRuleResult<AppState, AppAction>.deny('/collection/$defaultCollectionId/$recipeId');
  },
),
```

## Rule Ordering

Rules are evaluated top-to-bottom. Use this ordering:

1. **Loading guard** — redirect to splash if app hasn't loaded
2. **Forced update guard** — block everything if update required
3. **Authentication guard** — redirect unauthenticated users
4. **Deep link rewrites** — transform external URLs to internal routes
5. **Subscription/paywall guards** — block premium content
6. **Path aliases** — redirect legacy paths

This ensures that loading and update checks run before authentication, and authentication runs before feature-specific guards.

## Full Example

```dart
part of 'app.dart';

const publicRoutes = [
  Routes.splash,
  Routes.onboarding,
  Routes.signIn,
  Routes.signUp,
  Routes.forcedUpdate,
];

final rules = <ComposableRouteRule<AppState, AppAction>>[
  // 1. Loading guard
  ComposableRouteRule<AppState, AppAction>.guardAll(
    excludedPaths: [Routes.splash, Routes.onboarding],
    handler: (appState, location, pathParameters) {
      if (appState.shouldLoad) {
        return RouteRuleResult<AppState, AppAction>.deny(
          '${Routes.splash}?returnTo=${const Base64Encoder.urlSafe().convert(location.toString().codeUnits)}',
        );
      }
      return const RouteRuleResult<AppState, AppAction>.allow();
    },
  ),

  // 2. Forced update guard
  ComposableRouteRule<AppState, AppAction>.guardAll(
    excludedPaths: [Routes.splash, Routes.forcedUpdate],
    handler: (appState, location, pathParameters) {
      if (appState.shouldUpdate) {
        return const RouteRuleResult<AppState, AppAction>.deny(Routes.forcedUpdate);
      }
      return const RouteRuleResult<AppState, AppAction>.allow();
    },
  ),

  // 3. Authentication guard
  ComposableRouteRule<AppState, AppAction>.guardAll(
    excludedPaths: publicRoutes,
    handler: (appState, location, pathParameters) {
      if (appState.user == null) {
        return const RouteRuleResult<AppState, AppAction>.deny(Routes.signIn);
      }
      return const RouteRuleResult<AppState, AppAction>.allow();
    },
  ),

  // 4. Deep link rewrite
  ComposableRouteRule<AppState, AppAction>.guardOn(
    includedPaths: ['/recipe/share/:id'],
    handler: (appState, location, pathParameters) {
      final recipeId = pathParameters['id']!;
      return RouteRuleResult<AppState, AppAction>.deny('/recipe-loader?id=$recipeId');
    },
  ),

  // 5. Subscription guard
  ComposableRouteRule<AppState, AppAction>.guardOn(
    includedPaths: ['/recipe-loader'],
    handler: (appState, location, pathParameters) {
      if (appState.importInfo?.freeImports == 0 && !appState.isSubscribed) {
        return const RouteRuleResult<AppState, AppAction>.deny('/subscription');
      }
      return const RouteRuleResult<AppState, AppAction>.allow();
    },
  ),
];
```

## Checklist

- [ ] Rule added to `app.rule.dart` list
- [ ] Correct constructor used (`guardAll` for most routes, `guardOn` for specific routes, `guardWhen` for custom matching)
- [ ] `excludedPaths` / `includedPaths` match the intended routes
- [ ] `deny` redirect path is a valid route with a binding
- [ ] Rule order is correct (loading > update > auth > deep links > feature guards)
- [ ] Public routes list updated if new public routes were added
- [ ] `Routes` constants used instead of hardcoded strings
- [ ] Handler is stateless — only reads `AppState` and `Uri`/path parameters
