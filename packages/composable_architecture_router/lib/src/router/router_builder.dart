import 'package:flutter/widgets.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';

class RouterBuilder {
  final TransitionDelegate transitionDelegate;
  final Clip clipBehavior;
  final String? restorationId;
  final List<NavigatorObserver> observers;
  final Route? Function(RouteSettings settings)? onUnknownRoute;

  final bool Function(Route route, dynamic result)? didPop;

  RouterBuilder({
    this.transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
    this.clipBehavior = Clip.hardEdge,
    this.observers = const [],
    this.restorationId,
    this.onUnknownRoute,
    this.didPop,
  });

  Widget build(BuildContext context, GlobalKey<NavigatorState> key, List<ComposableRouterPage> pages) {
    if (pages.isEmpty) {
      return Container();
    }

    return Navigator(
      key: key,
      pages: pages,
      restorationScopeId: restorationId,
      clipBehavior: clipBehavior,
      onPopPage: (route, result) {
        route.popped.whenComplete(() => didPop?.call(route, result) ?? false);
        route.didPop(result);
        return true;
      },
      observers: observers,
      onUnknownRoute: onUnknownRoute,
      transitionDelegate: transitionDelegate,
    );
  }

  static RouterBuilder standard({required bool Function(Route route, dynamic result) didPop}) {
    return RouterBuilder(didPop: didPop);
  }
}
