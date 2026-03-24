part of 'main.dart';

class PageDRouteState {
  final int count;

  PageDRouteState(this.count);

  PageDRouteState copyWith({int? count}) =>
      PageDRouteState(count ?? this.count);
}

class PageDState {
  final int globalCount;
  final int count;

  PageDState(this.globalCount, this.count);

  int get totalCount => globalCount + count;

  PageDState copyWith({int? globalCount, int? count}) => PageDState(
      globalCount ?? this.globalCount, count ?? this.count);
}

sealed class PageDAction {
  const PageDAction();

  const factory PageDAction.increment() = PageDActionIncrement;

  const factory PageDAction.navigate(String location) = PageDActionNavigate;

  const factory PageDAction.incrementGlobal() = PageDActionIncrementGlobal;
}

class PageDActionIncrement extends PageDAction {
  const PageDActionIncrement() : super();
}

class PageDActionNavigate extends PageDAction {
  final String location;
  const PageDActionNavigate(
    this.location,
  ) : super();
}

class PageDActionIncrementGlobal extends PageDAction {
  const PageDActionIncrementGlobal() : super();
}

class PageDEnvironment {}

class PageD extends Routable<AppState, PageDRouteState, PageDState, AppAction,
    PageDAction, AppEnvironment, PageDEnvironment> {
  static final List<GlobalKey<NavigatorState>> keys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  RouteLens<AppState, PageDRouteState, PageDState?> get routeLens => (
        get: (appState, routeState) => buildLocalState(appState, routeState),
        set: (appState, routeState, localState) => localState == null
            ? (appState, routeState)
            : setBackFromLocalState(appState, routeState, localState),
      );

  Prism<AppAction, PageDAction, RouteID> get actionPrism => (
        extract: (globalAction) => extractAction(globalAction),
        embed: (routeID, localAction) => toAppAction(routeID, localAction),
      );

  @override
  Widget build(
    BuildContext context,
    Store<PageDState, PageDAction> store,
    NestedNavigator<AppState, AppAction> nestedNavigator,
  ) {
    debugPrint('${DateTime.now()} PageD.build (${store.state})');
    return Scaffold(
      appBar: AppBar(
        title: const Text("RouerTest"),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: WithTabController(
        nestedNavigator: nestedNavigator,
        length: 3,
        builder: (tabController) => Wrap(
          children: [
            const Text("Test"),
            Row(
              children: [
                MaterialButton(
                  onPressed: () => store
                      .send(const PageDAction.navigate('/tabs?selected=0')),
                  child: const Text("PageA"),
                ),
                MaterialButton(
                  onPressed: () => store
                      .send(const PageDAction.navigate('/tabs?selected=1')),
                  child: const Text("PageB"),
                ),
                MaterialButton(
                  onPressed: () => store
                      .send(const PageDAction.navigate('/tabs?selected=2')),
                  child: const Text("PageC"),
                ),
              ],
            ),
            SizedBox(
              height: 500,
              child: TabBarView(
                controller: tabController,
                children: nestedNavigator is TabNestedNavigator
                    ? (nestedNavigator as TabNestedNavigator)
                        .buildAll(context, keys)
                    : [const Center(), const Center(), const Center()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  PageDEnvironment buildLocalEnvironment(AppEnvironment env) => env.pageD;

  @override
  PageDState buildLocalState(AppState appState, PageDRouteState routeState) {
    return PageDState(appState.count, routeState.count);
  }

  @override
  (RouteID, PageDAction)? extractAction(AppAction action) =>
      action is AppActionPageD ? (action.id, action.action) : null;

  @override
  RouteID id(PageDRouteState routeState) => "pageD";

  PageDRouteState parseRouteStateFromRouteParams(
      {required Map<String, dynamic> pathParams,
      required Map<String, dynamic> queryParams,
      required PageDRouteState? currentRouteState}) {
    return PageDRouteState(queryParams['count'] as int? ?? 0);
  }

  @override
  Reducer<AppState, AppAction, AppEnvironment> reducer() =>
      Reducer<PageDState, PageDAction, PageDEnvironment>.transform(
        (state, action, env) => switch (action) {
          PageDActionIncrement _ =>
            state.copyWith(count: state.count + 1),
          PageDActionIncrementGlobal _ => state,
          _ => state,
        },
      ).pullbackRoute<AppState, PageDRouteState, AppAction, AppEnvironment>(
        routerStateLens: AppStateLens.navigation,
        routeLens: routeLens,
        actionPrism: actionPrism,
        toLocalEnvironment: buildLocalEnvironment,
      );

  @override
  (AppState, PageDRouteState) setBackFromLocalState(
    AppState appState,
    PageDRouteState routeState,
    PageDState localState,
  ) {
    return (
      appState,
      routeState.copyWith(count: localState.count),
    );
  }

  @override
  AppAction toAppAction(RouteID id, PageDAction action) {
    return AppAction.pageD(id, action);
  }
}
