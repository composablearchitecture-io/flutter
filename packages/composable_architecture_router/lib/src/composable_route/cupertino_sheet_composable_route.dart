part of 'index.dart';

class CupertinoSheetComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>
    extends ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> {
  @override
  final ListOfRoutesWithApp<AppState, AppAction>? nested;
  final CupertinoSheetOptions? options;

  const CupertinoSheetComposableRoute(
    super.routable,
    super.state, {
    this.nested,
    this.options,
  });

  @override
  CupertinoSheetComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> copyWith({
    RouteState? state,
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    CupertinoSheetOptions? options,
  }) =>
      CupertinoSheetComposableRoute(routable, state ?? this.state,
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

  CupertinoSheetOptions get defaultOptions => options ?? CupertinoSheetOptions();

  @override
  Route<void> buildRoute(
    BuildContext context,
    Widget Function(BuildContext context) builder,
    Page page,
  ) {
    return CupertinoModalPopupRoute(
      builder: builder,
      filter: defaultOptions.filter,
      barrierColor: CupertinoDynamicColor.resolve(defaultOptions.barrierColor, context),
      barrierDismissible: defaultOptions.barrierDismissible,
      semanticsDismissible: defaultOptions.semanticsDismissible,
      settings: page,
      anchorPoint: defaultOptions.anchorPoint,
    );
  }
}

class CupertinoSheetOptions {
  final ImageFilter? filter;
  final Color barrierColor;
  final bool barrierDismissible;
  final bool useRootNavigator;
  final bool semanticsDismissible;
  final Offset? anchorPoint;

  const CupertinoSheetOptions({
    this.filter,
    this.barrierColor = kCupertinoModalBarrierColor,
    this.barrierDismissible = true,
    this.useRootNavigator = true,
    this.semanticsDismissible = false,
    this.anchorPoint,
  });
}
