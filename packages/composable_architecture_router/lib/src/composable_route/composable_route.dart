part of 'index.dart';

typedef RouteID = String;

sealed class ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> {
  final Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic> routable;
  final RouteState state;

  const ComposableRoute(this.routable, this.state);

  factory ComposableRoute.page(
    Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic> routable,
    RouteState state, {
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    PageOptions? options,
  }) = PageComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>;

  factory ComposableRoute.cupertinoPage(
    Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic> routable,
    RouteState state, {
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    PageOptions? options,
  }) = CupertinoPageComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>;

  const factory ComposableRoute.sheet(
    Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic> routable,
    RouteState state, {
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    SheetOptions? options,
  }) = SheetComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>;

  const factory ComposableRoute.cupertinoSheet(
    Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic> routable,
    RouteState state, {
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    CupertinoSheetOptions? options,
  }) = CupertinoSheetComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>;

  const factory ComposableRoute.dialog(
    Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic> routable,
    RouteState state, {
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    DialogOptions options,
  }) = DialogComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>;

  const factory ComposableRoute.cupertinoDialog(
    Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic> routable,
    RouteState state, {
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    CupertinoDialogOptions options,
  }) = CupertinoDialogComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>;

  const factory ComposableRoute.tabs(
    Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic> routable,
    RouteState state,
    List<ListOfRoutesWithApp<AppState, AppAction>> tabs, {
    required int selectedTab,
    TabsOptions? options,
  }) = TabComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>;

  Store<LocalState?, LocalAction> scope(
          Store<AppState, AppAction> store, RouterState<AppState, AppAction> Function(AppState) toNavigatorState) =>
      routable.scope(id, store, toNavigatorState);

  ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> copyWith({
    RouteState? state,
  });

  ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> updateRouteStateOf(
      RouteID id, dynamic routeState);

  List<ComposableRoute<AppState, dynamic, dynamic, AppAction, dynamic>>? get nested => null;

  Routable<AppState, RouteState, LocalState, AppAction, LocalAction, dynamic, dynamic> get content => routable;

  RouteState get routeState => state;

  RouteID get id => content.id(routeState);

  AbstractNavigator<AppState, AppAction>? get navigator =>
      nested != null && nested!.isNotEmpty ? StackNavigator(nested!) : null;

  List<ComposableRouterPage<AppState, AppAction, dynamic, dynamic>> page(
    Store<AppState, AppAction> store,
    RouterState<AppState, AppAction> Function(AppState) toNavigatorState,
    RouterBuilder builder,
    BuildContext context, {
    ComposablePageArguments? arguments,
  }) {
    return [
      ComposableRouterPage<AppState, AppAction, LocalState, LocalAction>(
        store,
        this,
        toNavigatorState,
        builder,
        arguments: arguments,
      )
    ];
  }

  Route<void> createRoute(
    BuildContext context,
    Store<AppState, AppAction> store,
    Page page,
    RouterState<AppState, AppAction> Function(AppState) toNavigatorState,
    RouterBuilder builder,
  ) {
    return buildRoute(
      context,
      (context) => content.ifLetBuild(
        context,
        scope(store, toNavigatorState),
        () => restoreAndBuildNestedNavigators(id, store, toNavigatorState, builder, context),
      ),
      page,
    );
  }

  Route<void> buildRoute(
    BuildContext context,
    Widget Function(BuildContext context) builder,
    Page page,
  ) {
    return MaterialPageRoute(
      builder: builder,
      settings: page,
    );
  }

  NestedNavigator<AppState, AppAction> buildNestedNavigator(
    RouteID id,
    Store<AppState, AppAction> store,
    RouterState<AppState, AppAction> Function(AppState) toNavigatorState,
    RouterBuilder builder,
    BuildContext context,
  ) {
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

  NestedNavigator<AppState, AppAction> restoreAndBuildNestedNavigators(
    RouteID id,
    Store<AppState, AppAction> store,
    RouterState<AppState, AppAction> Function(AppState) toNavigatorState,
    RouterBuilder builder,
    BuildContext context,
  ) {
    final route = toNavigatorState(store.state).routeForId(id)
        as ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>?;
    if (route == null || route.navigator == null) {
      return NestedNavigator<AppState, AppAction>.none();
    } else {
      return route.buildNestedNavigator(id, store, toNavigatorState, builder, context);
    }
  }
}
