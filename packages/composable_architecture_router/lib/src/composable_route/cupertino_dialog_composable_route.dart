part of 'index.dart';

class CupertinoDialogComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>
    extends ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> {
  @override
  final ListOfRoutesWithApp<AppState, AppAction>? nested;
  final CupertinoDialogOptions options;

  const CupertinoDialogComposableRoute(
    super.routable,
    super.state, {
    this.nested,
    this.options = const CupertinoDialogOptions(),
  });

  @override
  CupertinoDialogComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> copyWith({
    RouteState? state,
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    CupertinoDialogOptions? options,
  }) =>
      CupertinoDialogComposableRoute(routable, state ?? this.state,
          nested: nested ?? this.nested, options: options ?? this.options);

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
    return CupertinoDialogRoute(
      context: context,
      barrierColor: options.barrierColor,
      anchorPoint: options.anchorPoint,
      barrierDismissible: options.barrierDismissible,
      barrierLabel: options.barrierLabel,
      settings: page,
      transitionBuilder: options.transitionBuilder,
      transitionDuration: options.transitionDuration,
      builder: builder,
    );
  }
}

class CupertinoDialogOptions {
  final Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)? transitionBuilder;
  final Duration transitionDuration;
  final String? barrierLabel;
  final Offset? anchorPoint;
  final Color? barrierColor;
  final bool barrierDismissible;

  const CupertinoDialogOptions({
    this.barrierDismissible = true,
    this.barrierLabel,
    this.anchorPoint,
    this.barrierColor,
    this.transitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 250),
  });
}
