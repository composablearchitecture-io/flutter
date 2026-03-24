import 'package:flutter/cupertino.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';
import 'package:composable_architecture_router/src/router/back_button_dispatcher.dart';
import 'package:composable_architecture_router/src/router/route_information_parser.dart';
import 'package:composable_architecture_router/src/router/route_information_provider.dart';
import 'package:composable_architecture_router/src/router/router_delegate.dart';

class ComposableRouter<AppState, AppAction> implements RouterConfig<RouterState<AppState, AppAction>> {
  final Store<AppState, AppAction> store;
  final RouterState<AppState, AppAction> Function(AppState state) toRouterState;
  final AppAction Function(RouterAction<AppState, AppAction> action) toAppAction;
  final RouterEnvironment<AppState, AppAction> environment;
  final Store<RouterState<AppState, AppAction>, RouterAction<AppState, AppAction>> routerStore;

  ComposableRouter({
    required this.store,
    required this.toRouterState,
    required this.toAppAction,
    required this.environment,
  }) : routerStore = store.scope(toLocalState: toRouterState, toGlobalAction: toAppAction) {
    routeInformationProvider = ComposableRouteInformationProvider(
      store: routerStore,
      resolver: (path) => environment.resolver(store.state, path),
    );
    routeInformationParser = ComposableRouteInformationParser(
      store: routerStore,
      resolver: (path) => environment.resolver(store.state, path),
    );
    routerDelegate = ComposableRouterDelegate(
      appStore: store,
      toNavigatorState: toRouterState,
      fromRouterAction: toAppAction,
    );
    backButtonDispatcher = ComposableBackButtonDispatcher(routerStore);
  }

  static Reducer<RouterState<AppState, AppAction>, RouterAction<AppState, AppAction>,
      RouterEnvironment<AppState, AppAction>> reducer<AppState, AppAction>(AppState appState) {
    return Reducer.transform(
      (state, action, env) {
        switch (action) {
          case RouterActionNavigate<AppState, AppAction>(:final location):
            final (finalLocation, stack) = env.resolver(appState, Uri.parse(location));
            return state.navigate(finalLocation, stack);
          case RouterActionPop<AppState, AppAction>():
            final pop = env.pop(state, appState);
            if (pop != null) {
              final (location, stack) = pop;
              return state.navigate(location, stack);
            }
            break;
          case RouterActionReset<AppState, AppAction>(:final state):
            return state.reset(state: state);
          case RouterActionRouteChanged<AppState, AppAction>():
            break;
        }
        return state;
      },
    );
  }

  @override
  BackButtonDispatcher? backButtonDispatcher;

  @override
  RouteInformationParser<RouterState<AppState, AppAction>>? routeInformationParser;

  @override
  RouteInformationProvider? routeInformationProvider;

  @override
  late RouterDelegate<RouterState<AppState, AppAction>> routerDelegate;
}
