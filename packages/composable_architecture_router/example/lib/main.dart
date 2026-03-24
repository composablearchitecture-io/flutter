import 'package:flutter/material.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';

part 'page_a.dart';
part 'page_b.dart';
part 'page_c.dart';
part 'page_d.dart';

void main() {
  runApp(const NestedTabNavigationExampleApp());
}

final Store<AppState, AppAction> store =
    Store.initial<AppState, AppAction, AppEnvironment>(
  appState,
  reducer,
  AppEnvironment(),
);

class AppState {
  final RouterState<AppState, AppAction> navigation;
  final int count;

  AppState(this.navigation, this.count);

  AppState copyWith(
          {RouterState<AppState, AppAction>? navigation, int? count}) =>
      AppState(navigation ?? this.navigation, count ?? this.count);
}

sealed class AppAction {
  const AppAction();

  const factory AppAction.navigation(RouterAction<AppState, AppAction> action) =
      AppActionNavigation;

  const factory AppAction.incrementGlobal() = AppActionIncrementGlobal;

  // Routes
  const factory AppAction.pageA(RouteID id, PageAAction action) =
      AppActionPageA;

  const factory AppAction.pageB(RouteID id, PageBAction action) =
      AppActionPageB;

  const factory AppAction.pageC(RouteID id, PageCAction action) =
      AppActionPageC;

  const factory AppAction.pageD(RouteID id, PageDAction action) =
      AppActionPageD;
// End Routes
}

class AppActionNavigation extends AppAction {
  final RouterAction<AppState, AppAction> action;
  const AppActionNavigation(
    this.action,
  ) : super();
}

class AppActionPageA extends AppAction {
  final RouteID id;
  final PageAAction action;
  const AppActionPageA(
    this.id,
    this.action,
  ) : super();
}

class AppActionPageB extends AppAction {
  final RouteID id;
  final PageBAction action;
  const AppActionPageB(
    this.id,
    this.action,
  ) : super();
}

class AppActionPageC extends AppAction {
  final RouteID id;
  final PageCAction action;
  const AppActionPageC(
    this.id,
    this.action,
  ) : super();
}

class AppActionPageD extends AppAction {
  final RouteID id;
  final PageDAction action;
  const AppActionPageD(
    this.id,
    this.action,
  ) : super();
}

class AppActionIncrementGlobal extends AppAction {
  const AppActionIncrementGlobal() : super();
}

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

class AppEnvironment {
  PageAEnvironment pageA = PageAEnvironment();
  PageBEnvironment pageB = PageBEnvironment();
  PageCEnvironment pageC = PageCEnvironment();
  PageDEnvironment pageD = PageDEnvironment();

  RouterEnvironment<AppState, AppAction> router = RouterEnvironment(
    store: () => store,
    rules: [],
    bindings: [
      ComposableRouteBinding.redirect(from: "/", to: "/home"),
      ComposableRouteBinding.matchOne(
        "/home",
        (state, _, __) => PageA().page(
          state.navigation,
          defaultRouteState: PageARouteState(0),
        ),
      ),
      ComposableRouteBinding.matchOne(
        '/b',
        (state, _, __) => PageB().page(
          state.navigation,
          defaultRouteState: PageBRouteState(0),
        ),
      ),
      ComposableRouteBinding<AppState, AppAction>.match(
        '/a/b',
        (state, _, __) => [
          PageA().page(
            state.navigation,
            defaultRouteState: PageARouteState(0),
          ),
          PageB().sheet(
            state.navigation,
            defaultRouteState: PageBRouteState(0),
            options: SheetOptions(
              showDragHandle: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              enableDrag: true,
              constraints: const BoxConstraints(
                maxHeight: 500,
              ),
            ),
          ),
        ],
        onPop: (appState, location, pathParameters) =>
            const OnPopResult.redirect('/'),
      ),
      ComposableRouteBinding<AppState, AppAction>.match(
        '/tabs',
        (state, location, __) {
          return [
            PageD().tabs(
              state.navigation,
              [
                [
                  PageA().page(
                    state.navigation,
                    defaultRouteState: PageARouteState(0),
                  ),
                ],
                [
                  PageB().page(
                    state.navigation,
                    defaultRouteState: PageBRouteState(0),
                  ),
                ],
                [
                  PageC().page(
                    state.navigation,
                    defaultRouteState: PageCRouteState(0),
                  ),
                ],
              ],
              currentTab:
                  location.queryParameters['selected']?.isNotEmpty == true
                      ? int.parse(location.queryParameters['selected']!)
                      : 0,
              defaultRouteState: PageDRouteState(0),
            ),
          ];
        },
        onPop: (appState, location, pathParameters) =>
            const OnPopResult.redirect('/'),
      ),
      ComposableRouteBinding.unknown(
        (
          appState,
          location,
          pathParameters,
        ) {
          throw UnimplementedError('Unknown route $location');
        },
      ),
    ],
  );
}

Reducer<AppState, AppAction, AppEnvironment> reducer =
    Reducer<AppState, AppAction, AppEnvironment>(
  reduce: (p0, p1, p2) {
    switch (p1) {
      case AppActionIncrementGlobal _:
        return (
          state: p0.copyWith(count: p0.count + 1),
          effect: const Effect.none(),
        );

      case AppActionPageA action:
        switch (action.action) {
          case PageAActionIncrementGlobal _:
            return (
              state: p0,
              effect: const Effect.value(AppAction.incrementGlobal()),
            );
          case PageAActionNavigate _:
            return (
              state: p0,
              effect: const Effect.value(
                AppAction.navigation(
                  RouterAction.navigate('/a/b'),
                ),
              ),
            );
          default:
            break;
        }

      case AppActionPageB action:
        switch (action.action) {
          case IncrementGlobalPageBAction _:
            return (
              state: p0,
              effect: const Effect.value(AppAction.incrementGlobal()),
            );
          case NavigatePageBAction _:
            return (
              state: p0,
              effect: const Effect.value(
                AppAction.navigation(
                  RouterAction.pop(),
                ),
              ),
            );
          default:
            break;
        }

      case AppActionPageC action:
        switch (action.action) {
          case PageCActionIncrementGlobal _:
            return (
              state: p0,
              effect: const Effect.value(AppAction.incrementGlobal()),
            );
          default:
            break;
        }

      case AppActionPageD action:
        switch (action.action) {
          case PageDActionIncrementGlobal _:
            return (
              state: p0,
              effect: const Effect.value(AppAction.incrementGlobal()),
            );
          case PageDActionNavigate a:
            return (
              state: p0,
              effect: Effect.value(
                AppAction.navigation(
                  RouterAction.navigate(a.location),
                ),
              ),
            );
          default:
            break;
        }
      default:
        break;
    }
    return (state: p0, effect: const Effect.none());
  },
).navigator(
  routerStateLens: AppStateLens.navigation,
  routerActionLens: AppActionLens.navigation,
  toNavigatorEnvironment: (env) => env.router,
  routes: [
    PageA(),
    PageB(),
    PageC(),
    PageD(),
  ],
);

final AppState appState = AppState(
  RouterState<AppState, AppAction>.initial(),
  0,
);

/// An example demonstrating how to use nested navigator
class NestedTabNavigationExampleApp extends StatelessWidget {
  /// Creates a NestedTabNavigationExampleApp
  const NestedTabNavigationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: ComposableRouter<AppState, AppAction>(
        store: store,
        toRouterState: (state) => state.navigation,
        toAppAction: (action) => AppAction.navigation(action),
        environment: AppEnvironment().router,
      ),
    );
  }
}
