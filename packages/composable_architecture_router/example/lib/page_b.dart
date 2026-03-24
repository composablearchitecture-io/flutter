part of 'main.dart';

class PageBRouteState {
  final int count;

  PageBRouteState(this.count);

  PageBRouteState copyWith({int? count}) =>
      PageBRouteState(count ?? this.count);
}

class PageBState {
  final int globalCount;
  final int count;

  PageBState(this.globalCount, this.count);

  int get totalCount => globalCount + count;

  PageBState copyWith({int? globalCount, int? count}) => PageBState(
      globalCount ?? this.globalCount, count ?? this.count);
}

sealed class PageBAction {
  const PageBAction();
  const factory PageBAction.increment() = IncrementPageBAction;
  const factory PageBAction.navigate() = NavigatePageBAction;
  const factory PageBAction.incrementGlobal() = IncrementGlobalPageBAction;
}

class IncrementPageBAction extends PageBAction {
  const IncrementPageBAction();
}

class NavigatePageBAction extends PageBAction {
  const NavigatePageBAction();
}

class IncrementGlobalPageBAction extends PageBAction {
  const IncrementGlobalPageBAction();
}

class PageBEnvironment {}

class PageB extends Routable<AppState, PageBRouteState, PageBState, AppAction,
    PageBAction, AppEnvironment, PageBEnvironment> {
  RouteLens<AppState, PageBRouteState, PageBState?> get routeLens => (
        get: (appState, routeState) => buildLocalState(appState, routeState),
        set: (appState, routeState, localState) => localState == null
            ? (appState, routeState)
            : setBackFromLocalState(appState, routeState, localState),
      );

  Prism<AppAction, PageBAction, RouteID> get actionPrism => (
        extract: (globalAction) => extractAction(globalAction),
        embed: (routeID, localAction) => toAppAction(routeID, localAction),
      );

  @override
  Widget build(BuildContext context, Store<PageBState, PageBAction> store,
      NestedNavigator<AppState, AppAction> nestedNavigator) {
    debugPrint('${DateTime.now()} PageB.build (${store.state})');
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            WithStore(
              store: store,
              builder: (state, send, context) => Text(
                'Counter: ${state.totalCount} (${state.globalCount} + ${state.count})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            TextButton(
              onPressed: () {
                store.send(const PageBAction.incrementGlobal());
              },
              child: const Text('Increment Global',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            TextButton(
              onPressed: () {
                debugPrint("${DateTime.now()} Button Tapped");
                store.send(const PageBAction.increment());
              },
              child: const Text('Increment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            TextButton(
              onPressed: () {
                store.send(const PageBAction.navigate());
              },
              child: const Text('Navigate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }

  @override
  PageBEnvironment buildLocalEnvironment(AppEnvironment env) => env.pageB;

  @override
  PageBState buildLocalState(AppState appState, PageBRouteState routeState) {
    return PageBState(appState.count, routeState.count);
  }

  @override
  (RouteID, PageBAction)? extractAction(AppAction action) =>
      action is AppActionPageB ? (action.id, action.action) : null;

  @override
  RouteID id(PageBRouteState routeState) => "pageB";

  @override
  Reducer<AppState, AppAction, AppEnvironment> reducer() =>
      Reducer<PageBState, PageBAction, PageBEnvironment>.transform(
        (state, action, env) => switch (action) {
          IncrementPageBAction _ =>
            state.copyWith(count: state.count + 1),
          IncrementGlobalPageBAction _ => state,
          _ => state,
        },
      ).pullbackRoute<AppState, PageBRouteState, AppAction, AppEnvironment>(
        routerStateLens: AppStateLens.navigation,
        routeLens: routeLens,
        actionPrism: actionPrism,
        toLocalEnvironment: buildLocalEnvironment,
      );

  @override
  (AppState, PageBRouteState) setBackFromLocalState(
    AppState appState,
    PageBRouteState routeState,
    PageBState localState,
  ) {
    return (
      appState,
      routeState.copyWith(count: localState.count),
    );
  }

  @override
  AppAction toAppAction(RouteID id, PageBAction action) {
    return AppAction.pageB(id, action);
  }
}
