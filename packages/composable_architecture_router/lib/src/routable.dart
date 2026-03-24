import 'package:flutter/widgets.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';

Map<RouteID, dynamic> _routeStateCache = {};

abstract class Routable<AppState, RouteState, State, AppAction, Action, AppEnvironment, Environment> {
  const Routable();

  RouteID id(RouteState routeState);

  Reducer<AppState, AppAction, AppEnvironment> reducer();

  Store<State?, Action> scope(
    RouteID id,
    Store<AppState, AppAction> store,
    RouterState<AppState, AppAction> Function(AppState appState) toNavigatorState,
  ) {
    return store.scope<State?, Action>(
      toLocalState: (global) {
        _routeStateCache[id] = toNavigatorState(global).routeStateForId(id) ?? _routeStateCache[id];
        return _routeStateCache[id] != null ? buildLocalState(global, _routeStateCache[id]) : null;
      },
      toGlobalAction: (local) => toAppAction(id, local),
    );
  }

  Widget build(BuildContext context, Store<State, Action> store, NestedNavigator<AppState, AppAction> nestedNavigator);

  Widget Function(BuildContext context)? get whenNullState => null;

  Widget ifLetBuild(
    BuildContext context,
    Store<State?, Action> store,
    NestedNavigator<AppState, AppAction> Function() nestedNavigator,
  ) =>
      IfLetStore(
        store: store,
        builder: (context, localStore) {
          return build(
            context,
            localStore,
            nestedNavigator(),
          );
        },
        orElse: whenNullState,
      );

  // Route pullback methods
  (RouteID, Action)? extractAction(AppAction action);

  AppAction toAppAction(RouteID id, Action action);

  State? buildLocalState(AppState appState, RouteState routeState);

  (AppState, RouteState) setBackFromLocalState(AppState appState, RouteState routeState, State localState);

  Environment buildLocalEnvironment(AppEnvironment env);

  // Route utility methods

  PageComposableRoute<AppState, RouteState, State, AppAction, Action> page(
    RouterState<AppState, AppAction> routerState, {
    required RouteState defaultRouteState,
    RouteID? routeId,
    RouteState Function(RouteState routeState)? overrideRouteState,
    PageOptions? options,
    List<RouteWithApp<AppState, AppAction>> nested = const [],
  }) {
    final routeState = routerState.routeStateForId(routeId ?? id(defaultRouteState)) ?? defaultRouteState;
    return ComposableRoute<AppState, RouteState, State, AppAction, Action>.page(
      this,
      overrideRouteState?.call(routeState) ?? routeState,
      nested: nested,
      options: options,
    ) as PageComposableRoute<AppState, RouteState, State, AppAction, Action>;
  }

  CupertinoPageComposableRoute<AppState, RouteState, State, AppAction, Action> cupertinoPage(
    RouterState<AppState, AppAction> routerState, {
    required RouteState defaultRouteState,
    RouteID? routeId,
    RouteState Function(RouteState routeState)? overrideRouteState,
    PageOptions? options,
    List<RouteWithApp<AppState, AppAction>> nested = const [],
  }) {
    final routeState = routerState.routeStateForId(routeId ?? id(defaultRouteState)) ?? defaultRouteState;
    return ComposableRoute<AppState, RouteState, State, AppAction, Action>.cupertinoPage(
      this,
      overrideRouteState?.call(routeState) ?? routeState,
      nested: nested,
      options: options,
    ) as CupertinoPageComposableRoute<AppState, RouteState, State, AppAction, Action>;
  }

  CupertinoSheetComposableRoute<AppState, RouteState, State, AppAction, Action> cupertinoSheet(
    RouterState<AppState, AppAction> routerState, {
    required RouteState defaultRouteState,
    RouteID? routeId,
    RouteState Function(RouteState routeState)? overrideRouteState,
    List<RouteWithApp<AppState, AppAction>> nested = const [],
    CupertinoSheetOptions? options,
  }) {
    final routeState = routerState.routeStateForId(routeId ?? id(defaultRouteState)) ?? defaultRouteState;
    return ComposableRoute<AppState, RouteState, State, AppAction, Action>.cupertinoSheet(
      this,
      overrideRouteState?.call(routeState) ?? routeState,
      nested: nested,
      options: options,
    ) as CupertinoSheetComposableRoute<AppState, RouteState, State, AppAction, Action>;
  }

  SheetComposableRoute<AppState, RouteState, State, AppAction, Action> sheet(
    RouterState<AppState, AppAction> routerState, {
    required RouteState defaultRouteState,
    RouteID? routeId,
    RouteState Function(RouteState routeState)? overrideRouteState,
    List<RouteWithApp<AppState, AppAction>> nested = const [],
    SheetOptions? options,
  }) {
    final routeState = routerState.routeStateForId(routeId ?? id(defaultRouteState)) ?? defaultRouteState;
    return ComposableRoute<AppState, RouteState, State, AppAction, Action>.sheet(
      this,
      overrideRouteState?.call(routeState) ?? routeState,
      nested: nested,
      options: options,
    ) as SheetComposableRoute<AppState, RouteState, State, AppAction, Action>;
  }

  DialogComposableRoute<AppState, RouteState, State, AppAction, Action> dialog(
    RouterState<AppState, AppAction> routerState, {
    required RouteState defaultRouteState,
    RouteID? routeId,
    RouteState Function(RouteState routeState)? overrideRouteState,
    List<RouteWithApp<AppState, AppAction>> nested = const [],
    DialogOptions options = const DialogOptions(),
  }) {
    final routeState = routerState.routeStateForId(routeId ?? id(defaultRouteState)) ?? defaultRouteState;
    return ComposableRoute<AppState, RouteState, State, AppAction, Action>.dialog(
      this,
      overrideRouteState?.call(routeState) ?? routeState,
      nested: nested,
      options: options,
    ) as DialogComposableRoute<AppState, RouteState, State, AppAction, Action>;
  }

  CupertinoDialogComposableRoute<AppState, RouteState, State, AppAction, Action> cupertinoDialog(
    RouterState<AppState, AppAction> routerState, {
    required RouteState defaultRouteState,
    RouteID? routeId,
    RouteState Function(RouteState routeState)? overrideRouteState,
    List<RouteWithApp<AppState, AppAction>> nested = const [],
    CupertinoDialogOptions options = const CupertinoDialogOptions(),
  }) {
    final routeState = routerState.routeStateForId(routeId ?? id(defaultRouteState)) ?? defaultRouteState;
    return ComposableRoute<AppState, RouteState, State, AppAction, Action>.cupertinoDialog(
      this,
      overrideRouteState?.call(routeState) ?? routeState,
      nested: nested,
      options: options,
    ) as CupertinoDialogComposableRoute<AppState, RouteState, State, AppAction, Action>;
  }

  TabComposableRoute<AppState, RouteState, State, AppAction, Action> tabs(
    RouterState<AppState, AppAction> routerState,
    List<List<RouteWithApp<AppState, AppAction>>> tabs, {
    required int currentTab,
    required RouteState defaultRouteState,
    bool restoreInactiveTabRouteStack = true,
    RouteID? routeId,
    RouteState Function(RouteState routeState)? overrideRouteState,
    TabsOptions? options,
  }) {
    final route = routerState.routeForId(routeId ?? id(defaultRouteState))
        as TabComposableRoute<AppState, RouteState, State, AppAction, Action>?;
    final List<List<RouteWithApp<AppState, AppAction>>> stacks;
    if (restoreInactiveTabRouteStack) {
      stacks = route?.tabs
              .enumerated()
              .map(
                (e) => e.key == currentTab ? tabs[currentTab] : e.value,
              )
              .toList() ??
          tabs;
    } else {
      stacks = tabs;
    }
    final routeState = routerState.routeStateForId(routeId ?? id(defaultRouteState)) ?? defaultRouteState;
    return ComposableRoute<AppState, RouteState, State, AppAction, Action>.tabs(
      this,
      overrideRouteState?.call(routeState) ?? routeState,
      stacks,
      selectedTab: currentTab,
      options: options,
    ) as TabComposableRoute<AppState, RouteState, State, AppAction, Action>;
  }
}

extension EnumeratedIterable<T> on Iterable<T> {
  Iterable<MapEntry<int, T>> enumerated() {
    var counter = 0;
    return map((e) => MapEntry(counter++, e));
  }
}
