import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide NavigatorState;
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';

extension on RouteInformation {
  bool get isEmpty => uri.path.isEmpty;
  bool isEqualTo(RouteInformation other) => uri == other.uri && state == other.state;
}

/// A route information provider that provides route information for the
/// [Router] widget
///
/// This provider is responsible for handing the route information through [value]
/// getter and notifies listeners, typically the [Router] widget, when a new
/// route information is available.
///
/// When the router opts for route information reporting (by overriding the
/// [RouterDelegate.currentConfiguration] to return non-null), override the
/// [routerReportsNewRouteInformation] method to process the route information.
///
/// See also:
///
///  * [PlatformRouteInformationProvider], which wires up the itself with the
///    [WidgetsBindingObserver.didPushRoute] to propagate platform push route
///    intent to the [Router] widget, as well as reports new route information
///    from the [Router] back to the engine by overriding the
///    [routerReportsNewRouteInformation].
class ComposableRouteInformationProvider<AppState, AppAction> extends RouteInformationProvider
    with WidgetsBindingObserver, ChangeNotifier {
  final Store<RouterState<AppState, AppAction>, RouterAction<AppState, AppAction>> store;

  final ComposableRouteResolver<AppState, AppAction> resolver;
  RouteInformation _value;
  @override
  RouteInformation get value => _value;

  ComposableRouteInformationProvider({required this.store, required this.resolver})
      : _value = store.state.toRouteInformation(resolver),
        super();

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    assert(routeInformation.state != null);
    final bool replace;
    switch (type) {
      case RouteInformationReportingType.none:
        replace = _value.isEmpty;
        break;
      case RouteInformationReportingType.neglect:
        replace = true;
        break;
      case RouteInformationReportingType.navigate:
        replace = false;
        break;
    }
    SystemNavigator.selectMultiEntryHistory();
    final routerState = RouterState.fromRouteInformation<AppState, AppAction>(routeInformation, resolver);

    try {
      SystemNavigator.routeInformationUpdated(
        uri: routeInformation.uri,
        state: routerState.toJson(),
        replace: replace,
      );
    } catch (e) {
      debugPrint('[NAV] Error serializing route information: $e');
    }

    if (!_value.isEqualTo(routeInformation)) {
      store.send(
        RouterAction<AppState, AppAction>.routeChanged(
          previous: RouterState.fromRouteInformation<AppState, AppAction>(_value, resolver),
          current: RouterState.fromRouteInformation<AppState, AppAction>(routeInformation, resolver),
        ),
      );
    }
    _value = routeInformation;
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      WidgetsBinding.instance.addObserver(this);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void dispose() {
    if (hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    assert(hasListeners);
    store.send(
      RouterAction<AppState, AppAction>.reset(
        RouterState.fromRouteInformation<AppState, AppAction>(routeInformation, resolver),
      ),
    );
    return SynchronousFuture(true);
  }

  @override
  Future<bool> didPushRoute(String route) {
    assert(hasListeners);
    return SynchronousFuture(true);
  }

  @override
  Future<bool> didPopRoute() {
    assert(hasListeners);
    store.send(RouterAction<AppState, AppAction>.pop());
    return SynchronousFuture(true);
  }
}
