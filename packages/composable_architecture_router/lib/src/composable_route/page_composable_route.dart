part of 'index.dart';

class PageComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>
    extends ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> {
  @override
  final ListOfRoutesWithApp<AppState, AppAction>? nested;
  final PageOptions? options;

  const PageComposableRoute(super.routable, super.state, {this.nested, this.options});

  @override
  PageComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> copyWith({
    RouteState? state,
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    PageOptions? options,
  }) =>
      PageComposableRoute(routable, state ?? this.state, nested: nested ?? this.nested, options: options ?? this.options);

  @override
  ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> updateRouteStateOf(
      RouteID id, dynamic routeState) {
    if (id == this.id && routeState is RouteState) {
      return copyWith(state: routeState);
    }
    return copyWith(
      nested: nested
          ?.map(
            (r) => r.updateRouteStateOf(id, routeState),
          )
          .toList(),
    );
  }

  @override
  Route<void> buildRoute(
    BuildContext context,
    Widget Function(BuildContext context) builder,
    Page page,
  ) {
    if (options?.shouldAnimate ?? true) {
      return MaterialPageRoute(
        builder: builder,
        settings: page,
        allowSnapshotting: options?.allowSnapshotting ?? true,
        barrierDismissible: options?.barrierDismissible ?? false,
        directionalTraversalEdgeBehavior: options?.directionalTraversalEdgeBehavior,
        fullscreenDialog: options?.fullscreenDialog ?? false,
        maintainState: options?.maintainState ?? true,
        requestFocus: options?.requestFocus ?? false,
        traversalEdgeBehavior: options?.traversalEdgeBehavior,
      );
    } else {
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => builder(context),
        settings: page,
        allowSnapshotting: options?.allowSnapshotting ?? true,
        barrierDismissible: options?.barrierDismissible ?? false,
        maintainState: options?.maintainState ?? true,
        opaque: options?.fullscreenDialog ?? false,
        transitionsBuilder: options?.transitionsBuilder ?? _defaultTransitionsBuilder,
        transitionDuration: options?.transitionDuration ?? Duration.zero,
        reverseTransitionDuration: options?.reverseTransitionDuration ?? Duration.zero,
      );
    }
  }

  @override
  List<ComposableRouterPage<AppState, AppAction, dynamic, dynamic>> page(
    Store<AppState, AppAction> store,
    RouterState<AppState, AppAction> Function(AppState) toNavigatorState,
    RouterBuilder builder,
    BuildContext context, {
    ComposablePageArguments? arguments,
  }) {
    if (options?.flattenNestedBreakpoint != null &&
        options!.flattenNestedBreakpoint! >= MediaQuery.sizeOf(context).width) {
      final newArgs = arguments?.copyWith(isFlattened: true) ?? ComposablePageArguments(isFlattened: true);
      return [
        ComposableRouterPage<AppState, AppAction, LocalState, LocalAction>(
          store,
          this,
          toNavigatorState,
          builder,
          arguments: newArgs,
        ),
        ...(navigator?.pages(store, toNavigatorState, builder, context, arguments: newArgs) ?? []),
      ];
    } else {
      return super.page(store, toNavigatorState, builder, context, arguments: arguments);
    }
  }

  @override
  NestedNavigator<AppState, AppAction> buildNestedNavigator(
    RouteID id,
    Store<AppState, AppAction> store,
    RouterState<AppState, AppAction> Function(AppState) toNavigatorState,
    RouterBuilder builder,
    BuildContext context,
  ) {
    if (options?.flattenNestedBreakpoint != null &&
        options!.flattenNestedBreakpoint! >= MediaQuery.sizeOf(context).width) {
      return NestedNavigator<AppState, AppAction>.none();
    }
    return NestedNavigator<AppState, AppAction>.single(
      builder,
      nested
              ?.map(
                (r) => r.page(store, toNavigatorState, builder, context),
              )
              .expand((e) => e)
              .toList(growable: false) ??
          [],
    );
  }
}

Widget _defaultTransitionsBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return child;
}

class PageOptions {
  final double? flattenNestedBreakpoint;
  final bool shouldAnimate;
  final bool allowSnapshotting;
  final bool barrierDismissible;
  final bool fullscreenDialog;
  final bool maintainState;
  final bool requestFocus;
  final TraversalEdgeBehavior? traversalEdgeBehavior;
  final TraversalEdgeBehavior? directionalTraversalEdgeBehavior;
  final Widget Function(BuildContext, Animation<double>, Animation<double>, Widget) transitionsBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  const PageOptions({
    this.flattenNestedBreakpoint,
    this.shouldAnimate = true,
    this.allowSnapshotting = true,
    this.barrierDismissible = false,
    this.fullscreenDialog = false,
    this.maintainState = true,
    this.requestFocus = true,
    this.traversalEdgeBehavior,
    this.directionalTraversalEdgeBehavior,
    this.transitionsBuilder = _defaultTransitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
  });
}
