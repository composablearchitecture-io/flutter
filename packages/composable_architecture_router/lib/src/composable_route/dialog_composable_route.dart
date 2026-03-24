part of 'index.dart';

class DialogComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>
    extends ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> {
  @override
  final ListOfRoutesWithApp<AppState, AppAction>? nested;
  final DialogOptions options;

  const DialogComposableRoute(
    super.routable,
    super.state, {
    this.nested,
    this.options = const DialogOptions(),
  });

  @override
  DialogComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> copyWith({
    RouteState? state,
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    DialogOptions? options,
  }) =>
      DialogComposableRoute(routable, state ?? this.state,
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
    return DialogRoute(
      builder: (context) {
        final child = builder(context);
        if (options.fullscreen) {
          return Dialog.fullscreen(
            backgroundColor: options.backgroundColor,
            insetAnimationCurve: options.insetAnimationCurve,
            insetAnimationDuration: options.insetAnimationDuration,
            child: child,
          );
        } else {
          return Dialog(
            alignment: options.alignment,
            backgroundColor: options.backgroundColor,
            clipBehavior: options.clipBehavior,
            elevation: options.elevation,
            insetAnimationCurve: options.insetAnimationCurve,
            insetAnimationDuration: options.insetAnimationDuration,
            insetPadding: options.insetPadding,
            shape: options.shape,
            shadowColor: options.shadowColor,
            surfaceTintColor: options.surfaceTintColor,
            child: child,
          );
        }
      },
      context: context,
      settings: page,
      barrierLabel: options.barrierLabel,
      anchorPoint: options.anchorPoint,
      barrierColor: options.barrierColor,
      barrierDismissible: options.barrierDismissible,
      themes: options.themes,
      traversalEdgeBehavior: options.traversalEdgeBehavior,
      useSafeArea: options.useSafeArea,
    );
  }
}

class DialogOptions {
  //Dialog options
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Duration insetAnimationDuration;
  final Curve insetAnimationCurve;
  final EdgeInsets insetPadding;
  final Clip clipBehavior;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  final bool fullscreen;

  //DialogRoute options
  final String? barrierLabel;
  final Offset? anchorPoint;
  final Color? barrierColor;
  final bool barrierDismissible;
  final CapturedThemes? themes;
  final TraversalEdgeBehavior? traversalEdgeBehavior;
  final bool useSafeArea;

  const DialogOptions({
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
    this.clipBehavior = Clip.none,
    this.shape,
    this.alignment,
    this.fullscreen = false,
    this.barrierDismissible = true,
    this.useSafeArea = true,
    this.barrierLabel,
    this.anchorPoint,
    this.barrierColor,
    this.themes,
    this.traversalEdgeBehavior,
  });
}
