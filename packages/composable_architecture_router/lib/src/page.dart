import 'package:flutter/widgets.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/src/router/router_builder.dart';
import 'package:composable_architecture_router/src/state.dart';
import 'package:composable_architecture_router/src/utils/typedefs.dart';

class ComposableRouterPage<AppState, AppAction, LocalState, LocalAction> extends Page<void> {
  final Store<AppState, AppAction> store;
  final RouteWithAppAndLocal<AppState, AppAction, LocalState, LocalAction> route;
  final RouterState<AppState, AppAction> Function(AppState) toNavigatorState;
  final RouterBuilder builder;

  ComposableRouterPage(this.store, this.route, this.toNavigatorState, this.builder, {super.arguments})
      : super(key: ValueKey(route.id));

  @override
  Route<void> createRoute(BuildContext context) {
    return route.createRoute(context, store, this, toNavigatorState, builder);
  }
}
