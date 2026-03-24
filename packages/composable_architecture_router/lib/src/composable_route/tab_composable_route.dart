part of 'index.dart';

class TabComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>
    extends ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> {
  final List<ListOfRoutesWithApp<AppState, AppAction>> tabs;
  final int selectedTab;
  final TabsOptions? options;

  const TabComposableRoute(
    super.routable,
    super.state,
    this.tabs, {
    required this.selectedTab,
    this.options,
  });

  @override
  TabComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> copyWith({
    RouteState? state,
    List<ListOfRoutesWithApp<AppState, AppAction>>? tabs,
    int? selectedTab,
    TabsOptions? options,
  }) =>
      TabComposableRoute(routable, state ?? this.state, tabs ?? this.tabs,
          selectedTab: selectedTab ?? this.selectedTab, options: options ?? this.options);

  @override
  ComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> updateRouteStateOf(
      RouteID id, dynamic routeState) {
    if (id == this.id && routeState is RouteState) {
      return copyWith(state: routeState);
    }
    return copyWith(
      tabs: tabs
          .map(
            (r) => r.map((r) => r.updateRouteStateOf(id, routeState)).toList(),
          )
          .toList(),
    );
  }

  @override
  AbstractNavigator<AppState, AppAction>? get navigator =>
      tabs.isNotEmpty ? TabNavigator(tabs.map((e) => StackNavigator<AppState, AppAction>(e)).toList(), 0) : null;

  @override
  NestedNavigator<AppState, AppAction> buildNestedNavigator(
    RouteID id,
    Store<AppState, AppAction> store,
    RouterState<AppState, AppAction> Function(AppState p1) toNavigatorState,
    RouterBuilder builder,
    BuildContext context,
  ) {
    return NestedNavigator<AppState, AppAction>.tabs(
      builder,
      tabs
          .map(
            (t) => t
                .map((r) => r.page(store, toNavigatorState, builder, context))
                .expand((e) => e)
                .toList(growable: false),
          )
          .toList(growable: false),
      selectedTab,
    );
  }
}

class TabsOptions {
  const TabsOptions();
}
