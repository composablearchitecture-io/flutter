# composable_architecture_router

A declarative, composable Navigator 2.0 integration for Flutter built on the [Composable Architecture](https://pub.dev/packages/composable_architecture_core).

Routes are values — defined as data, matched via bindings, guarded by rules, and rendered as pages. Navigation state lives in your `Store`, enabling time-travel debugging, deep linking, and full testability.

## Features

- **Declarative routing** — define routes as data bindings, not widget trees
- **Deep linking** — automatic path parameter extraction and URL synchronization
- **Route guards** — protect routes with composable rules (auth gates, feature flags)
- **Multiple presentation styles** — pages, bottom sheets, dialogs, Cupertino variants
- **Tab & nested navigation** — first-class support for tab bars with independent stacks
- **Responsive navigation** — flatten nested routes at breakpoints for adaptive layouts
- **State restoration** — full browser history and state serialization support
- **Composable reducers** — route-scoped reducers compose into the app reducer via `pullback`

## Getting Started

Add the dependency:

```yaml
dependencies:
  composable_architecture_router: ^0.1.0
```

## Core Concepts

### RouterState & RouterAction

Navigation state is modeled as `RouterState<AppState, AppAction>`, which holds the current `Uri` location and a `StackNavigator` containing the active route stack. Navigation is driven by dispatching `RouterAction`:

```dart
// Navigate to a path
store.send(AppAction.navigation(RouterAction.navigate('/profile/42')));

// Pop the current route
store.send(AppAction.navigation(RouterAction.pop()));

// Reset navigation state
store.send(AppAction.navigation(RouterAction.reset(newState)));
```

### Defining Routes with `Routable`

Each screen implements `Routable`, which defines how the route integrates with the composable architecture:

```dart
class ProfilePage extends Routable<AppState, ProfileRouteState, ProfileState,
    AppAction, ProfileAction, AppEnvironment, ProfileEnvironment> {
  @override
  RouteID id(ProfileRouteState state) => 'profile_${state.userId}';

  @override
  Reducer<ProfileState, ProfileAction, ProfileEnvironment> reducer() =>
      profileReducer;

  @override
  Widget build(BuildContext context, Store<ProfileState?, ProfileAction> store,
      NestedNavigator nested) {
    return ProfileScreen(store: store);
  }

  // ... scope, extractAction, toAppAction, buildLocalState, etc.
}
```

`Routable` provides multiple presentation methods out of the box:

```dart
// Material page
ProfilePage().page(routerState, defaultRouteState: ProfileRouteState(userId));

// Cupertino page
ProfilePage().cupertinoPage(routerState, defaultRouteState: ProfileRouteState(userId));

// Bottom sheet
ProfilePage().sheet(routerState,
  defaultRouteState: ProfileRouteState(userId),
  options: SheetOptions(showDragHandle: true),
);

// Dialog
ProfilePage().dialog(routerState,
  defaultRouteState: ProfileRouteState(userId),
  options: DialogOptions(barrierDismissible: true),
);

// Cupertino sheet / dialog
ProfilePage().cupertinoSheet(routerState, defaultRouteState: ProfileRouteState(userId));
ProfilePage().cupertinoDialog(routerState, defaultRouteState: ProfileRouteState(userId));

// Tabs with independent navigation stacks
TabsPage().tabs(routerState, [
  [PageA().page(routerState, defaultRouteState: PageAState())],
  [PageB().page(routerState, defaultRouteState: PageBState())],
], currentTab: 0, defaultRouteState: TabsRouteState());
```

### Route Bindings

`ComposableRouteBinding` maps URL patterns to route stacks:

```dart
RouterEnvironment(
  store: () => store,
  rules: [],
  bindings: [
    // Redirect
    ComposableRouteBinding.redirect(from: "/", to: "/home"),

    // Single page for a path
    ComposableRouteBinding.matchOne(
      "/home",
      (state, location, params) => HomePage().page(
        state.navigation,
        defaultRouteState: HomeRouteState(),
      ),
    ),

    // Multiple pages (e.g., page + sheet overlay)
    ComposableRouteBinding.match(
      '/profile/:id',
      (state, location, params) => [
        ProfilePage().page(
          state.navigation,
          defaultRouteState: ProfileRouteState(params['id']!),
        ),
      ],
    ),

    // Deep link pattern matching
    ComposableRouteBinding.deepLinkFrom(
      pattern: RegExp(r'^myapp://product/(\d+)$'),
    ),

    // Unknown route handler
    ComposableRouteBinding.unknown(
      (state, location, params) =>
          RouteBindingResult.redirect('/not-found'),
    ),
  ],
);
```

Path templates support named parameters (e.g., `/:id`, `/users/:userId/posts/:postId`) which are automatically extracted into the path parameters map.

### Route Guards

`ComposableRouteRule` lets you guard routes with composable conditions:

```dart
rules: [
  // Guard specific paths (e.g., require auth)
  ComposableRouteRule.guardOn(
    includedPaths: ['/settings', '/profile'],
    handler: (state, location, params) {
      if (!state.isLoggedIn) return RouteRuleResult.deny('/login');
      return RouteRuleResult.allow();
    },
  ),

  // Guard all paths except some
  ComposableRouteRule.guardAll(
    excludedPaths: ['/login', '/register'],
    handler: (state, location, params) {
      if (!state.isLoggedIn) return RouteRuleResult.deny('/login');
      return RouteRuleResult.allow();
    },
  ),

  // Guard based on dynamic conditions
  ComposableRouteRule.guardWhen(
    queryParams: (state) =>
        state.featureDisabled ? {'reason': 'maintenance'} : null,
    handler: (state, location, params) =>
        RouteRuleResult.deny('/maintenance'),
  ),
],
```

Guard results:
- `RouteRuleResult.allow()` — proceed normally
- `RouteRuleResult.deny('/redirect')` — redirect to another path
- `RouteRuleResult.forceAllow()` — bypass all subsequent rules

### Pop Behavior

Control what happens when a route is popped:

```dart
ComposableRouteBinding.match(
  '/checkout',
  (state, location, params) => [/* ... */],
  onPop: (appState, location, params) =>
      const OnPopResult.redirect('/cart'),  // redirect on pop
      // OnPopResult.prevent()              // block pop
      // OnPopResult.system()               // default system behavior
),
```

### ComposableRouter

Wire everything together with `ComposableRouter`, which implements Flutter's `RouterConfig`:

```dart
MaterialApp.router(
  routerConfig: ComposableRouter<AppState, AppAction>(
    store: store,
    toRouterState: (state) => state.navigation,
    toAppAction: (action) => AppAction.navigation(action),
    environment: appEnvironment.router,
  ),
);
```

### Composing the Reducer

Use the `.navigator()` extension to compose route reducers into your app reducer:

```dart
Reducer<AppState, AppAction, AppEnvironment> appReducer =
    Reducer<AppState, AppAction, AppEnvironment>(
  reduce: (state, action, env) {
    // handle non-navigation actions...
    return (state: state, effect: const Effect.none());
  },
).navigator(
  routerStateLens: AppStateLens.navigation,
  routerActionLens: AppActionLens.navigation,
  toNavigatorEnvironment: (env) => env.router,
  routes: [HomePage(), ProfilePage(), SettingsPage()],
);
```

### Tab Navigation with `WithTabController`

For tab-based navigation, use `WithTabController` to manage `TabController` lifecycle:

```dart
WithTabController(
  length: 3,
  nestedNavigator: nestedNavigator,
  builder: (context, controller, nested) {
    return Scaffold(
      body: TabBarView(
        controller: controller,
        children: nested.buildAll(context, tabKeys),
      ),
      bottomNavigationBar: TabBar(
        controller: controller,
        tabs: [Tab(text: 'A'), Tab(text: 'B'), Tab(text: 'C')],
      ),
    );
  },
);
```

### Nested Navigation

Routes can contain nested navigation stacks. `NestedNavigator` is a sealed class with variants:

- `NestedNavigator.none()` — no nested content
- `NestedNavigator.single(builder, pages)` — single nested navigator
- `NestedNavigator.multi(builder, stacks)` — multiple parallel stacks
- `NestedNavigator.tabs(builder, stacks, currentTab)` — tab-based stacks

### Responsive Navigation

Use `PageOptions.flattenNestedBreakpoint` to flatten nested navigators into the parent stack on wider screens:

```dart
ProfilePage().page(
  routerState,
  defaultRouteState: ProfileRouteState(userId),
  options: PageOptions(flattenNestedBreakpoint: 600),
);
```

### Page Transition Customization

`PageOptions` provides full control over page transitions:

```dart
PageOptions(
  shouldAnimate: false,              // disable animation
  transitionsBuilder: myTransition,  // custom transition
  transitionDuration: Duration(milliseconds: 300),
  fullscreenDialog: true,
  maintainState: false,
)
```

## Key Types

| Type | Description |
|------|-------------|
| `RouterState<S, A>` | Navigation state: current URI + route stack |
| `RouterAction<S, A>` | Navigation actions: navigate, pop, reset |
| `Routable` | Abstract base for route definitions |
| `ComposableRoute` | Sealed route variants: page, sheet, dialog, tabs |
| `ComposableRouter` | Flutter `RouterConfig` implementation |
| `ComposableRouteBinding` | URL pattern → route stack mapping |
| `ComposableRouteRule` | Route guard with allow/deny/forceAllow |
| `RouterEnvironment` | Bindings + rules + store reference |
| `NestedNavigator` | Sealed nested navigation: none, single, multi, tabs |
| `RouterBuilder` | Configurable navigator widget builder |
| `RouteID` | Type alias for `String` route identifiers |

## License

MIT — see [LICENSE](https://github.com/composablearchitecture-io/flutter/blob/main/LICENSE).
