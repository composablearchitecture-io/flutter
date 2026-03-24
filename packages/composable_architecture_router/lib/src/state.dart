import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';
import 'package:composable_architecture_router/src/router/router_builder.dart';

class RouterState<AppState, AppAction> {
  StackNavigator<AppState, AppAction> main;
  Uri location;

  RouterState(this.location, this.main);

  factory RouterState.initial() {
    return RouterState(
      Uri(),
      StackNavigator([]),
    );
  }

  RouterState<AppState, AppAction> copyWith({
    Uri? location,
    StackNavigator<AppState, AppAction>? main,
  }) =>
      RouterState(location ?? this.location, main ?? this.main);

  int get count => main.count;

  static RouterState<AppState, AppAction> fromRouteInformation<AppState, AppAction>(
    RouteInformation routeInformation,
    ComposableRouteResolver<AppState, AppAction> resolver,
  ) {
    RouterState<AppState, AppAction>? state;
    if (routeInformation.state is RouterState<AppState, AppAction>) {
      state = routeInformation.state as RouterState<AppState, AppAction>;
    } else if (routeInformation.state is String) {
      try {
        final savedState = RouterState.fromJson<AppState, AppAction>(routeInformation.state as String);
        final (location, stack) = resolver(savedState.location);
        state = RouterState(
          location,
          StackNavigator(
            stack,
          ).copyWithRouteStatesFrom(savedState.main),
        );
      } catch (e) {
        debugPrint('[NAV] Error parsing route information state: $e');
      }
    }
    if (state != null) {
      return state;
    }
    final (location, stack) = resolver(routeInformation.uri);
    return RouterState(
      location,
      StackNavigator(
        stack,
      ),
    );
  }

  RouteWithApp<AppState, AppAction> get topMostRoute => main.topMostRoute;

  AbstractNavigator<AppState, AppAction> get currentNavigator => main.currentNavigator;

  RouteInformation toRouteInformation(ComposableRouteResolver<AppState, AppAction> resolver) {
    if (this.main.routes.isEmpty) {
      final (location, stack) = resolver(Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName));
      return RouteInformation(uri: location, state: RouterState(location, StackNavigator(stack)));
    }
    return RouteInformation(
      uri: location,
      state: this,
    );
  }

  RouteWithApp<AppState, AppAction>? find({required RouteID id}) => main.find(id: id);

  AbstractNavigator<AppState, AppAction>? navigatorForRouteId(RouteID routeId) => main.navigatorForRouteId(routeId);

  RouteState? routeStateForId<RouteState>(RouteID id) {
    return main.find(id: id)?.routeState as RouteState?;
  }

  RouteWithApp<AppState, AppAction>? routeForId(RouteID id) {
    return main.find(id: id);
  }

  List<ComposableRouterPage> pages(
    Store<AppState, AppAction> store,
    RouterState<AppState, AppAction> Function(AppState) toNavigatorState,
    RouterBuilder builder,
    BuildContext context,
  ) =>
      main.pages(store, toNavigatorState, builder, context);

  RouterState<AppState, AppAction> navigate(Uri location, List<RouteWithApp<AppState, AppAction>> stack) {
    return copyWith(
      location: location,
      main: main.copyWith(
        routes: stack,
      ),
    );
  }

  RouterState<AppState, AppAction> reset({required RouterState<AppState, AppAction> state}) {
    return state;
  }

  RouterState<AppState, AppAction> updateRouteStateOf(RouteID routeID, dynamic routeState) {
    return copyWith(main: main.updateRouteStateOf(routeID, routeState));
  }

  String toJson() => jsonEncode({'location': location.toString()});

  static RouterState<AppState, AppAction> fromJson<AppState, AppAction>(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return RouterState(
      Uri.parse(map['location'] as String),
      StackNavigator([]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouterState && location == other.location;

  @override
  int get hashCode => location.hashCode;

  @override
  String toString() => 'RouterState(location: $location, routes: ${main.routes.length})';
}

class StackNavigator<AppState, AppAction> extends AbstractNavigator<AppState, AppAction> {
  @override
  List<RouteWithApp<AppState, AppAction>> routes;

  StackNavigator(this.routes);

  StackNavigator<AppState, AppAction> copyWith({
    List<RouteWithApp<AppState, AppAction>>? routes,
  }) =>
      StackNavigator(routes ?? this.routes);

  @override
  StackNavigator<AppState, AppAction> updateRouteStateOf(RouteID routeID, dynamic routeState) {
    return copyWith(routes: routes.map((r) => r.updateRouteStateOf(routeID, routeState)).toList());
  }

  StackNavigator<AppState, AppAction> copyWithRouteStatesFrom(StackNavigator<AppState, AppAction> saved) {
    return copyWith(
      routes: routes.map((r) {
        final savedRoute = saved.find(id: r.id);
        if (savedRoute != null) {
          return r.copyWith(state: savedRoute.routeState);
        }
        return r;
      }).toList(),
    );
  }

  @override
  String toString() => 'StackNavigator(routes: ${routes.length})';
}

class TabNavigator<AppState, AppAction> extends AbstractNavigator<AppState, AppAction> {
  List<AbstractNavigator<AppState, AppAction>> nestedNavigators;
  int currentTab = 0;

  @override
  List<RouteWithApp<AppState, AppAction>> get routes => nestedNavigators[currentTab].routes;

  TabNavigator(this.nestedNavigators, this.currentTab);

  TabNavigator<AppState, AppAction> copyWith({
    List<AbstractNavigator<AppState, AppAction>>? nestedNavigators,
    int? currentTab,
  }) =>
      TabNavigator(nestedNavigators ?? this.nestedNavigators, currentTab ?? this.currentTab);

  @override
  RouteWithApp<AppState, AppAction>? find({required RouteID id}) {
    return nestedNavigators.map((e) => e.find(id: id)).where((e) => e != null).firstOrNull;
  }

  @override
  TabNavigator<AppState, AppAction> updateRouteStateOf(RouteID routeID, dynamic routeState) {
    return copyWith(nestedNavigators: nestedNavigators.map((e) => e.updateRouteStateOf(routeID, routeState)).toList());
  }

  @override
  String toString() => 'TabNavigator(tabs: ${nestedNavigators.length}, currentTab: $currentTab)';
}

abstract class AbstractNavigator<AppState, AppAction> {
  List<RouteWithApp<AppState, AppAction>> get routes;

  int get count => routes.length + (routes.last.navigator?.count ?? 0);

  RouteWithApp<AppState, AppAction> get topMostRoute => routes.last.navigator?.topMostRoute ?? routes.last;

  AbstractNavigator<AppState, AppAction> get currentNavigator => routes.last.navigator?.currentNavigator ?? this;

  List<ComposableRouterPage<AppState, AppAction, dynamic, dynamic>> pages(
          Store<AppState, AppAction> store,
          RouterState<AppState, AppAction> Function(AppState) toNavigatorState,
          RouterBuilder builder,
          BuildContext context,
          {ComposablePageArguments? arguments}) =>
      routes
          .map((r) => r.page(store, toNavigatorState, builder, context, arguments: arguments))
          .expand((e) => e)
          .toList();

  RouteWithApp<AppState, AppAction>? find({required RouteID id}) {
    return routes.where((r) => r.id == id).firstOrNull ?? _findInChildren(id: id);
  }

  RouteWithApp<AppState, AppAction>? _findInChildren({required RouteID id}) {
    return routes.map((r) => r.navigator?.find(id: id)).where((r) => r != null).firstOrNull;
  }

  AbstractNavigator<AppState, AppAction>? navigatorForRouteId(RouteID routeId) {
    return routes.where((r) => r.id == routeId).isNotEmpty ? this : _navigatorForRouteIdInChildren(routeId);
  }

  AbstractNavigator<AppState, AppAction>? _navigatorForRouteIdInChildren(RouteID routeId) {
    return routes.map((r) => r.navigator?.navigatorForRouteId(routeId)).where((r) => r != null).firstOrNull;
  }

  AbstractNavigator<AppState, AppAction> updateRouteStateOf(RouteID routeID, dynamic routeState);
}
