import 'package:composable_architecture_router/composable_architecture_router.dart';

typedef RoutableWithApp<AppState, AppAction>
    = Routable<AppState, dynamic, dynamic, AppAction, dynamic, dynamic, dynamic>;
typedef RoutableWithAppEnv<AppState, AppAction, AppEnvironment>
    = Routable<AppState, dynamic, dynamic, AppAction, dynamic, AppEnvironment, dynamic>;
typedef RouteWithApp<AppState, AppAction> = ComposableRoute<AppState, dynamic, dynamic, AppAction, dynamic>;
typedef ListOfRoutesWithApp<AppState, AppAction> = List<RouteWithApp<AppState, AppAction>>;
typedef RoutableWithAppAndLocal<AppState, AppAction, LocalState, LocalAction>
    = Routable<AppState, dynamic, LocalState, AppAction, LocalAction, dynamic, dynamic>;
typedef RoutableWithAppLocalAndRoute<AppState, RouteState, AppAction, LocalState, LocalAction>
    = Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic>;
typedef RouteWithLocal<LocalState, LocalAction> = ComposableRoute<dynamic, dynamic, LocalState, dynamic, LocalAction>;
typedef RouteWithAppAndLocal<AppState, AppAction, LocalState, LocalAction>
    = ComposableRoute<AppState, dynamic, LocalState, AppAction, LocalAction>;

typedef RouteBindingResolver<AppState, AppAction> = RouteBindingResult<AppState, AppAction> Function(
    AppState appState, Uri location, Map<String, String> pathParameters);

typedef RouteOnPopHandler<AppState, AppAction> = OnPopResult<AppState, AppAction> Function(
    AppState appState, Uri location, Map<String, String> pathParameters);

typedef ComposableRouteResolver<AppState, AppAction> = (Uri, List<RouteWithApp<AppState, AppAction>>) Function(
    Uri path);

typedef RouteRuleHandler<AppState, AppAction> = RouteRuleResult<AppState, AppAction> Function(
  AppState appState,
  Uri location,
  Map<String, String> pathParameters,
);

typedef RouteFailureHandler<AppState, AppAction> = RouteBindingResult<AppState, AppAction> Function(
  AppState appState,
  Uri location,
  Map<String, String> pathParameters,
  Object error,
);
