---
name: create-binding
description: Create route bindings for composable_architecture_router — mapping URL paths to page stacks with path parameters, query parameters, redirects, pop behavior, dialogs, sheets, and tabs.
argument-hint: <path-pattern>
---

# Create Binding

Define route bindings that map URL paths to page stacks using `ComposableRouteBinding` from `composable_architecture_router`. Bindings are the core of the declarative routing system — they describe which `Routable` pages, sheets, dialogs, and tabs should appear for a given URL.

## Prerequisites

```yaml
dependencies:
  composable_architecture_router: ^0.1.0
```

## Conventions

1. Bindings are defined in `app.bindings.dart` as a `List<ComposableRouteBinding<AppState, AppAction>>`
2. Each binding maps a URL path template to a list of `ComposableRoute` objects (the page stack)
3. Path parameters use `:param` syntax (e.g., `/user/:id`)
4. Path parameters can be constrained with regex: `/:tab(recipes|mealPlan|profile)`
5. Bindings are matched in order — first match wins
6. Every `match`/`matchOne` binding should have an `onPop` handler that redirects to its parent
7. Query parameters are accessed via `location.queryParameters`
8. Reuse shared page stacks by extracting helper functions (e.g., `generateHomeTabsRoute`)
9. Route constants should be defined in a separate `Routes` class for type safety and reuse

## Binding Constructors

### `matchOne` — Single page

Returns a single `ComposableRoute`. Use when the path maps to exactly one page with no underlying stack:

```dart
ComposableRouteBinding.matchOne(
  '/onboarding',
  (state, location, pathParams) => Onboarding().page(
    state.navigation,
    defaultRouteState: OnboardingRouteState(currentSlide: 0),
  ),
),
```

### `match` — Page stack

Returns a `List<ComposableRoute>`. Use when the path requires multiple pages in the stack (e.g., a detail page on top of a list, or a dialog on top of a page):

```dart
ComposableRouteBinding.match(
  '/favourites',
  (state, location, pathParams) => [
    generateHomeTabsRoute(state, page: ExercisePage.training),
    Favourites().page(
      state.navigation,
      defaultRouteState: FavouritesRouteState(),
    ),
  ],
  onPop: (appState, location, pathParameters) =>
      const OnPopResult.redirect(Routes.training),
),
```

### `redirect` — URL redirect

```dart
ComposableRouteBinding.redirect(from: '/', to: '/training'),
```

### `unknown` — Fallback for unmatched paths

```dart
ComposableRouteBinding.unknown(
  (state, location, pathParams) => RouteBindingResult.redirect('/not-found'),
),
```

### `failure` — Error handler

```dart
ComposableRouteBinding.failure(
  (state, location, pathParams) => RouteBindingResult.redirect('/error'),
),
```

### `deepLinkFrom` — Regex-based deep link matching

```dart
ComposableRouteBinding.deepLinkFrom(
  pattern: RegExp(r'^https://example\.com/(.*)$'),
),
```

## Path Parameters

### Simple parameters

```dart
ComposableRouteBinding.matchOne(
  '/user/:id',
  (state, location, pathParams) => UserProfile().page(
    state.navigation,
    defaultRouteState: UserProfileRouteState(
      id: pathParams['id']!,
    ),
  ),
),
```

### Constrained parameters (regex)

Restrict parameter values using parenthesized regex:

```dart
// Only match specific tab values
final listOfPages = ExercisePage.values.map((e) => e.toValue()).join('|');

ComposableRouteBinding.matchOne(
  '/:tab($listOfPages|profile)',
  (state, location, pathParams) =>
      generateHomeTabsRoute(state, tab: pathParams['tab']!),
),
```

### Multiple path parameters

```dart
ComposableRouteBinding.match(
  '/:pageId($listOfPages)/section/:sectionId/category/:id',
  (state, location, pathParams) => [
    generateHomeTabsRoute(state, tab: pathParams['pageId']!),
    Category().page(
      state.navigation,
      defaultRouteState: CategoryRouteState(
        id: pathParams['id']!,
        page: ExercisePageMapper.fromValue(pathParams['pageId']!),
        sectionId: pathParams['sectionId']!,
      ),
    ),
  ],
  onPop: (appState, location, pathParameters) =>
      const OnPopResult.redirect(Routes.wellness),
),
```

## Query Parameters

Access query parameters from the `location` URI:

```dart
ComposableRouteBinding.match(
  '/match',
  (state, location, pathParams) => [
    generateHomeTabsRoute(
      state,
      tab: location.queryParameters['returnTo']?.decodeReturnTo ?? 'match',
    ),
    Match().page(
      state.navigation,
      defaultRouteState: MatchRouteState(isMatchActive: false),
    ),
  ],
  onPop: (appState, location, pathParameters) {
    final returnTo =
        location.queryParameters['returnTo']?.decodeReturnTo ?? Routes.training;
    return OnPopResult.redirect(returnTo);
  },
),
```

## Presentation Types

### Page (standard navigation push)

```dart
MyFeature().page(
  state.navigation,
  defaultRouteState: MyFeatureRouteState(),
),
```

With options:

```dart
MyFeature().page(
  state.navigation,
  defaultRouteState: MyFeatureRouteState(),
  options: const PageOptions(shouldAnimate: false),
),
```

### Sheet (bottom sheet)

```dart
MyFeature().sheet(
  state.navigation,
  defaultRouteState: MyFeatureRouteState(),
  options: SheetOptions(
    useSafeArea: true,
    backgroundColor: Colors.white,
    clipBehavior: Clip.hardEdge,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
),
```

Non-dismissible sheet:

```dart
SetupWizard().sheet(
  state.navigation,
  defaultRouteState: SetupWizardRouteState(),
  options: const SheetOptions(
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    clipBehavior: Clip.hardEdge,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
),
```

### Dialog

```dart
GenericDialog().dialog(
  state.navigation,
  defaultRouteState: GenericDialogRouteState(
    variant: DialogVariant.confirmDelete(),
  ),
  options: DialogOptions(
    barrierColor: Colors.black.withValues(alpha: 0.6),
  ),
),
```

### Cupertino variants

```dart
// Cupertino page
MyFeature().cupertinoPage(state.navigation, defaultRouteState: MyFeatureRouteState());

// Cupertino sheet
MyFeature().cupertinoSheet(state.navigation, defaultRouteState: MyFeatureRouteState());

// Cupertino dialog
MyFeature().cupertinoDialog(state.navigation, defaultRouteState: MyFeatureRouteState());
```

### Tabs

```dart
HomeTabs().tabs(
  state.navigation,
  [
    [Home().page(state.navigation, defaultRouteState: HomeRouteState())],
    [Settings().page(state.navigation, defaultRouteState: SettingsRouteState())],
    [Profile().page(state.navigation, defaultRouteState: ProfileRouteState())],
  ],
  currentTab: 0,
  defaultRouteState: HomeTabsRouteState(),
),
```

Each inner list is a tab's page stack — tabs can themselves contain nested navigation.

## Pop Behavior (`onPop`)

Every `match`/`matchOne` binding can define `onPop` to control what happens when the user navigates back:

### Redirect to parent

```dart
onPop: (appState, location, pathParameters) =>
    const OnPopResult.redirect(Routes.home),
```

### Dynamic redirect based on query parameters

```dart
onPop: (appState, location, pathParameters) {
  final returnTo =
      location.queryParameters['returnTo']?.decodeReturnTo ?? Routes.home;
  return OnPopResult.redirect(returnTo);
},
```

### Dynamic redirect based on app state

```dart
onPop: (appState, location, pathParameters) {
  final exerciseIdentifier = appState.loaded!.currentExercise!;
  final route = switch (exerciseIdentifier.page) {
    ExercisePage.wellness when exerciseIdentifier.categoryId != null =>
      '/${exerciseIdentifier.pageId}/section/${exerciseIdentifier.sectionId}/category/${exerciseIdentifier.categoryId}',
    _ => '/${exerciseIdentifier.pageId}',
  };
  return OnPopResult.redirect(route);
},
```

### Prevent pop

```dart
onPop: (appState, location, pathParameters) => const OnPopResult.prevent(),
```

### System default pop

```dart
onPop: (appState, location, pathParameters) => const OnPopResult.system(),
```

## Accessing State in Bindings

### Reading route state from a previous route in the stack

Use `routeStateForId` to read the state of a route already in the navigation stack:

```dart
ComposableRouteBinding.match(
  Routes.signUpEmailConfirmation,
  (state, location, pathParams) {
    final signup = state.navigation.routeStateForId<SignupRouteState>('signup')!;
    return [
      Signin().page(state.navigation, defaultRouteState: SigninRouteState()),
      EmailConfirmation().page(
        state.navigation,
        defaultRouteState: EmailConfirmationRouteState(
          email: signup.email,
          token: pathParams['token'],
        ),
      ),
    ];
  },
  onPop: (appState, location, pathParameters) =>
      const OnPopResult.redirect(Routes.signIn),
),
```

### Reading app-level state

```dart
ComposableRouteBinding.match(
  Routes.exercise,
  (state, location, pathParams) {
    final exerciseIdentifier = state.loaded!.currentExercise!;
    return [
      generateHomeTabsRoute(state, page: exerciseIdentifier.page),
      ExerciseDetail().page(
        state.navigation,
        defaultRouteState: ExerciseDetailRouteState(
          input: exerciseIdentifier,
        ),
      ),
    ];
  },
),
```

### Overriding route state on deep links

Use `overrideRouteState` when a deep link should update an existing route's state:

```dart
ComposableRouteBinding.match(
  Routes.deepLinkEmailConfirmation,
  (state, location, pathParams) => [
    Signin().page(state.navigation, defaultRouteState: SigninRouteState()),
    EmailConfirmation().page(
      state.navigation,
      defaultRouteState: EmailConfirmationRouteState(
        email: '',
        token: pathParams['token'],
      ),
      overrideRouteState: (routeState) =>
          routeState.copyWith(token: pathParams['token']),
    ),
  ],
  onPop: (appState, location, pathParameters) =>
      const OnPopResult.redirect(Routes.signIn),
),
```

## Shared Options & Helpers

### Reusable presentation options

Define shared options at the top of the bindings file to keep styling consistent:

```dart
final dialogOptions = DialogOptions(
  barrierColor: AppColors.neutralDark800.withValues(alpha: 0.6),
);

final sheetOptions = SheetOptions(
  modalBarrierColor: AppColors.neutralDark800.withValues(alpha: 0.6),
  backgroundColor: AppColors.neutralDark1000,
);
```

### Shared tab route helper

When many bindings share the same base tab structure, extract a helper function:

```dart
ComposableRoute<AppState, dynamic, dynamic, AppAction, dynamic>
    generateHomeTabsRoute(AppState state, {String? tab, ExercisePage? page}) {
  assert(tab != null || page != null, 'Either tab or page must be provided');
  final tabString = tab ?? page!.toValue();
  return HomeTabs().tabs(
    state.navigation,
    [
      [Home().page(state.navigation, defaultRouteState: HomeRouteState())],
      [Wellness().page(state.navigation, defaultRouteState: WellnessRouteState())],
      [Profile().page(state.navigation, defaultRouteState: ProfileRouteState())],
    ],
    currentTab: switch (tabString) {
      'training' => 0,
      'wellness' => 1,
      'profile' => 2,
      _ => 0,
    },
    defaultRouteState: HomeTabsRouteState(),
  );
}
```

Then reference it across bindings:

```dart
ComposableRouteBinding.match(
  Routes.favourites,
  (state, location, pathParams) => [
    generateHomeTabsRoute(state, page: ExercisePage.training),
    Favourites().page(state.navigation, defaultRouteState: FavouritesRouteState()),
  ],
  onPop: (appState, location, pathParameters) =>
      const OnPopResult.redirect(Routes.training),
),
```

### Routes constants class

```dart
abstract class Routes {
  static const training = '/training';
  static const wellness = '/wellness';
  static const profile = '/profile';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const favourites = '/favourites';
  static const exercise = '/exercise';
  static const calendar = '/calendar';
  static String exerciseDetail(String id) => '/exercise/$id';

  // Templates with path parameters
  static const homeTemplate = '/:tab(training|wellness|profile)';
}
```

## Route Rules (Guards)

Rules are evaluated before bindings. Define them in `app.rule.dart`:

### Guard specific paths

```dart
ComposableRouteRule.guardOn(
  includedPaths: ['/settings', '/profile'],
  handler: (state, location, pathParams) {
    if (!state.isLoggedIn) return RouteRuleResult.deny('/login');
    return RouteRuleResult.allow();
  },
),
```

### Guard all except exclusions

```dart
ComposableRouteRule.guardAll(
  excludedPaths: ['/login', '/register', '/onboarding'],
  handler: (state, location, pathParams) {
    if (!state.isLoggedIn) return RouteRuleResult.deny('/login');
    return RouteRuleResult.allow();
  },
),
```

### Custom guard condition

```dart
ComposableRouteRule.guardWhen(
  bindsTo: (location, allPaths) {
    // Custom matching logic — return path params Map if matches, null otherwise
    if (location.path.startsWith('/admin')) return {};
    return null;
  },
  handler: (state, location, pathParams) {
    if (!state.isAdmin) return RouteRuleResult.deny('/');
    return RouteRuleResult.allow();
  },
),
```

### Rule results

- `RouteRuleResult.allow()` — proceed to binding resolution
- `RouteRuleResult.deny('/redirect-path')` — redirect, skip binding
- `RouteRuleResult.forceAllow()` — proceed and skip all remaining rules

## Common Patterns

### Stacked pages with dialog on top

```dart
ComposableRouteBinding.match(
  Routes.matchQuitDialog,
  (state, location, pathParams) => [
    generateHomeTabsRoute(state, tab: 'match'),
    Match().page(
      state.navigation,
      defaultRouteState: MatchRouteState(isMatchActive: false),
    ),
    GenericDialog().dialog(
      state.navigation,
      defaultRouteState: GenericDialogRouteState(
        variant: DialogVariant.matchQuitAlert(),
      ),
      options: dialogOptions,
    ),
  ],
  onPop: (appState, location, pathParameters) =>
      OnPopResult.redirect(Routes.match),
),
```

### Sheet on top of a page

```dart
ComposableRouteBinding.match(
  Routes.categoryInfo,
  (state, location, pathParams) => [
    generateHomeTabsRoute(state, tab: pathParams['pageId']!),
    Category().page(
      state.navigation,
      defaultRouteState: CategoryRouteState(id: pathParams['id']!),
    ),
    CategoryExtra().sheet(
      state.navigation,
      defaultRouteState: CategoryExtraRouteState(id: pathParams['id']!),
      options: sheetOptions,
    ),
  ],
  onPop: (appState, location, pathParameters) =>
      OnPopResult.redirect(location.path.replaceAll('/info', '')),
),
```

### Conditional page stack based on state

```dart
ComposableRouteBinding.match(
  Routes.exercise,
  (state, location, pathParams) {
    final exercise = state.loaded!.currentExercise!;
    final isReturnToCalendar =
        location.queryParameters['returnTo']?.decodeReturnTo == Routes.calendar;
    return [
      generateHomeTabsRoute(state, page: exercise.page),
      if (exercise.categoryId != null && !isReturnToCalendar)
        Category().page(
          state.navigation,
          defaultRouteState: CategoryRouteState(id: exercise.categoryId!),
        ),
      if (isReturnToCalendar)
        Calendar().page(
          state.navigation,
          defaultRouteState: CalendarRouteState(selectedDay: DateTime.now()),
        ),
      ExerciseDetail().page(
        state.navigation,
        defaultRouteState: ExerciseDetailRouteState(input: exercise),
      ),
    ];
  },
),
```

### Auth flow with sign-up → email confirmation chain

```dart
ComposableRouteBinding.match(
  Routes.signUp,
  (state, location, pathParams) {
    final provider = location.queryParameters['signInProvider']
            ?.let(MapperContainer.globals.fromValue<SignInProvider>) ??
        SignInProvider.email;
    final idToken = location.queryParameters['idToken'];
    return [
      Signin().page(state.navigation, defaultRouteState: SigninRouteState()),
      Signup().page(
        state.navigation,
        defaultRouteState: SignupRouteState.fromProvider(
          provider: provider,
          idToken: idToken,
        ),
      ),
    ];
  },
  onPop: (appState, location, pathParameters) =>
      const OnPopResult.redirect(Routes.signIn),
),
```

## Checklist

- [ ] Binding added to `app.bindings.dart` list
- [ ] Correct constructor used (`matchOne` for single page, `match` for stack, `redirect` for redirect)
- [ ] Path template matches the expected URL pattern
- [ ] Path parameters accessed via `pathParams['name']!`
- [ ] Query parameters accessed via `location.queryParameters['name']`
- [ ] `onPop` handler defined with appropriate redirect target
- [ ] Shared base pages (tabs, auth) reused via helper functions
- [ ] Dialog/sheet options defined as reusable top-level variables if used in multiple bindings
- [ ] Route constants used instead of hardcoded strings
- [ ] `Routable` subclass created for each new page in the stack (use `create-route` skill)
- [ ] Guards added to `app.rule.dart` if the route requires authentication or role checks
