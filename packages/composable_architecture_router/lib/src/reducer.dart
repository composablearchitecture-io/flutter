import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';

extension NavigationReducer<State, Action, Environment> on Reducer<State, Action, Environment> {
  Reducer<GlobalState, GlobalAction, GlobalEnvironment>
      pullbackRoute<GlobalState, RouteState, GlobalAction, GlobalEnvironment>({
    required Lens<GlobalState, RouterState<GlobalState, GlobalAction>> routerStateLens,
    required RouteLens<GlobalState, RouteState, State?> routeLens,
    required Prism<GlobalAction, Action, RouteID> actionPrism,
    required Environment Function(GlobalEnvironment) toLocalEnvironment,
  }) =>
          _pullbackRoute(
            toNavigatorState: routerStateLens.get,
            fromNavigationState: routerStateLens.set,
            toLocalState: routeLens.get,
            fromLocalState: routeLens.set,
            toLocalAction: actionPrism.extract,
            toGlobalAction: actionPrism.embed,
            toLocalEnvironment: toLocalEnvironment,
          );

  Reducer<GlobalState, GlobalAction, GlobalEnvironment>
      _pullbackRoute<GlobalState, RouteState, GlobalAction, GlobalEnvironment>({
    required RouterState<GlobalState, GlobalAction> Function(GlobalState) toNavigatorState,
    required GlobalState Function(GlobalState, RouterState<GlobalState, GlobalAction>) fromNavigationState,
    required State? Function(GlobalState, RouteState) toLocalState,
    required (GlobalState, RouteState) Function(GlobalState, RouteState, State) fromLocalState,
    required (RouteID, Action)? Function(GlobalAction) toLocalAction,
    required GlobalAction Function(RouteID, Action) toGlobalAction,
    required Environment Function(GlobalEnvironment) toLocalEnvironment,
  }) {
    return Reducer<GlobalState, GlobalAction, GlobalEnvironment>(
      reduce: (GlobalState state, GlobalAction action, GlobalEnvironment env) {
        final extracted = toLocalAction(action);
        if (extracted == null) {
          return (state: state, effect: Effect.none());
        }
        final (routeID, localAction) = extracted;
        final navigatorState = toNavigatorState(state);
        final routeState = navigatorState.routeStateForId(routeID);
        if (routeState == null) {
          return (state: state, effect: Effect.none());
        }
        final localState = toLocalState(state, routeState);
        if (localState == null) {
          return (state: state, effect: Effect.none());
        }
        final localEnvironment = toLocalEnvironment(env);
        final (state: newLocalState, effect: effect) = reduce(localState, localAction, localEnvironment);
        final (newGlobalState, newRouteState) = fromLocalState(state, routeState, newLocalState);
        final newNavigationState = navigatorState.updateRouteStateOf(routeID, newRouteState);
        final resultingState = fromNavigationState(newGlobalState, newNavigationState);
        return (
          state: resultingState,
          effect: effect.map((e) => toGlobalAction(routeID, e)),
        );
      },
    );
  }

  Reducer<State, Action, Environment> navigator({
    required Lens<State, RouterState<State, Action>> routerStateLens,
    required ActionLens<Action, RouterAction<State, Action>> routerActionLens,
    required RouterEnvironment<State, Action> Function(Environment) toNavigatorEnvironment,
    required List<RoutableWithAppEnv<State, Action, Environment>> routes,
  }) {
    return Reducer<State, Action, Environment>.combine(
      [
            this,
            Reducer<State, Action, Environment>(
              reduce: (state, action, env) {
                return ComposableRouter.reducer<State, Action>(state)
                    .pullback(
                      stateLens: routerStateLens,
                      actionLens: routerActionLens,
                      toLocalEnvironment: toNavigatorEnvironment,
                    )
                    .reduce(state, action, env);
              },
            ),
          ] +
          routes.map((route) => route.reducer()).toList(),
    );
  }
}
