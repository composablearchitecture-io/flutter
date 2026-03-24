import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';

/// A delegate that is used by the [Router] widget to parse a route information
/// into a configuration of type T.
///
/// This delegate is used when the [Router] widget is first built with initial
/// route information from [Router.routeInformationProvider] and any subsequent
/// new route notifications from it. The [Router] widget calls the [parseRouteInformation]
/// with the route information from [Router.routeInformationProvider].
///
/// One of the [parseRouteInformation] or
/// [parseRouteInformationWithDependencies] must be implemented, otherwise a
/// runtime error will be thrown.
class ComposableRouteInformationParser<AppState, AppAction>
    extends RouteInformationParser<RouterState<AppState, AppAction>> {
  final Store<RouterState<AppState, AppAction>, RouterAction<AppState, AppAction>> store;
  final ComposableRouteResolver<AppState, AppAction> resolver;

  /// Default constructor
  ComposableRouteInformationParser({required this.store, required this.resolver});

  @override
  Future<RouterState<AppState, AppAction>> parseRouteInformationWithDependencies(
    RouteInformation routeInformation,
    BuildContext context,
  ) {
    return SynchronousFuture<RouterState<AppState, AppAction>>(
      RouterState.fromRouteInformation<AppState, AppAction>(routeInformation, resolver),
    );
  }

  @override
  RouteInformation? restoreRouteInformation(RouterState<AppState, AppAction> configuration) {
    return RouteInformation(
      uri: configuration.location,
      state: configuration,
    );
  }
}
