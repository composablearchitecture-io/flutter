part of 'index.dart';

class SheetComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>
    extends ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> {
  @override
  final ListOfRoutesWithApp<AppState, AppAction>? nested;
  final SheetOptions? options;

  const SheetComposableRoute(super.routable, super.state, {this.nested, this.options});

  @override
  SheetComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> copyWith({
    RouteState? state,
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    SheetOptions? options,
  }) =>
      SheetComposableRoute(routable, state ?? this.state, nested: nested ?? this.nested, options: options ?? this.options);

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
    return ModalBottomSheetRoute(
      builder: builder,
      settings: page,
      isScrollControlled: options?.isScrollControlled ?? true,
      isDismissible: options?.isDismissible ?? true,
      anchorPoint: options?.anchorPoint,
      backgroundColor: options?.backgroundColor,
      barrierLabel: options?.barrierLabel,
      barrierOnTapHint: options?.barrierOnTapHint,
      capturedThemes: options?.capturedThemes,
      clipBehavior: options?.clipBehavior,
      constraints: options?.constraints,
      elevation: options?.elevation,
      enableDrag: options?.enableDrag ?? true,
      shape: options?.shape,
      modalBarrierColor: options?.modalBarrierColor,
      showDragHandle: options?.showDragHandle,
      sheetAnimationStyle: options?.sheetAnimationStyle,
      useSafeArea: options?.useSafeArea ?? true,
    );
  }
}

class SheetOptions {
  final bool isScrollControlled;
  final bool isDismissible;
  final Offset? anchorPoint;
  final Color? backgroundColor;
  final String? barrierLabel;
  final String? barrierOnTapHint;
  final CapturedThemes? capturedThemes;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;
  final double? elevation;
  final bool enableDrag;
  final ShapeBorder? shape;
  final Color? modalBarrierColor;
  final bool? showDragHandle;
  final AnimationStyle? sheetAnimationStyle;
  final bool useSafeArea;

  const SheetOptions({
    this.isScrollControlled = true,
    this.isDismissible = true,
    this.enableDrag = true,
    this.useSafeArea = true,
    this.anchorPoint,
    this.backgroundColor,
    this.barrierLabel,
    this.barrierOnTapHint,
    this.capturedThemes,
    this.clipBehavior,
    this.constraints,
    this.elevation,
    this.shape,
    this.modalBarrierColor,
    this.showDragHandle,
    this.sheetAnimationStyle,
  });
}
