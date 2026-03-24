part of 'main.dart';

class PageCRouteState {
  final int count;

  PageCRouteState(this.count);

  PageCRouteState copyWith({int? count}) =>
      PageCRouteState(count ?? this.count);
}

class PageCState {
  final int globalCount;
  final int count;

  PageCState(this.globalCount, this.count);

  int get totalCount => globalCount + count;

  PageCState copyWith({int? globalCount, int? count}) => PageCState(
      globalCount ?? this.globalCount, count ?? this.count);
}

sealed class PageCAction {
  const PageCAction();
  const factory PageCAction.increment() = PageCActionIncrement;
  const factory PageCAction.navigate() = PageCActionNavigate;
  const factory PageCAction.incrementGlobal() = PageCActionIncrementGlobal;
}

class PageCActionIncrement extends PageCAction {
  const PageCActionIncrement() : super();
}

class PageCActionNavigate extends PageCAction {
  const PageCActionNavigate() : super();
}

class PageCActionIncrementGlobal extends PageCAction {
  const PageCActionIncrementGlobal() : super();
}

class PageCEnvironment {}

class PageC extends Routable<AppState, PageCRouteState, PageCState, AppAction,
    PageCAction, AppEnvironment, PageCEnvironment> {
  RouteLens<AppState, PageCRouteState, PageCState?> get routeLens => (
        get: (appState, routeState) => buildLocalState(appState, routeState),
        set: (appState, routeState, localState) => localState == null
            ? (appState, routeState)
            : setBackFromLocalState(appState, routeState, localState),
      );

  Prism<AppAction, PageCAction, RouteID> get actionPrism => (
        extract: (globalAction) => extractAction(globalAction),
        embed: (routeID, localAction) => toAppAction(routeID, localAction),
      );

  @override
  Widget build(
    BuildContext context,
    Store<PageCState, PageCAction> store,
    NestedNavigator<AppState, AppAction> nestedNavigator,
  ) {
    debugPrint('${DateTime.now()} PageC.build (${store.state})');
    return Scaffold(
      backgroundColor: Colors.green,
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
                store.send(const PageCAction.incrementGlobal());
              },
              child: const Text('Increment Global',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            TextButton(
              onPressed: () {
                debugPrint("${DateTime.now()} Button Tapped");
                store.send(const PageCAction.increment());
              },
              child: const Text('Increment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            TextButton(
              onPressed: () {
                store.send(const PageCAction.navigate());
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
  PageCEnvironment buildLocalEnvironment(AppEnvironment env) => env.pageC;

  @override
  PageCState buildLocalState(AppState appState, PageCRouteState routeState) {
    return PageCState(appState.count, routeState.count);
  }

  @override
  (RouteID, PageCAction)? extractAction(AppAction action) =>
      action is AppActionPageC ? (action.id, action.action) : null;

  @override
  RouteID id(PageCRouteState routeState) => "pageC";

  @override
  Reducer<AppState, AppAction, AppEnvironment> reducer() =>
      Reducer<PageCState, PageCAction, PageCEnvironment>.transform(
        (state, action, env) => switch (action) {
          PageCActionIncrement _ =>
            state.copyWith(count: state.count + 1),
          PageCActionIncrementGlobal _ => state,
          _ => state,
        },
      ).pullbackRoute<AppState, PageCRouteState, AppAction, AppEnvironment>(
        routerStateLens: AppStateLens.navigation,
        routeLens: routeLens,
        actionPrism: actionPrism,
        toLocalEnvironment: buildLocalEnvironment,
      );

  @override
  (AppState, PageCRouteState) setBackFromLocalState(
    AppState appState,
    PageCRouteState routeState,
    PageCState localState,
  ) {
    return (
      appState,
      routeState.copyWith(count: localState.count),
    );
  }

  @override
  AppAction toAppAction(RouteID id, PageCAction action) {
    return AppAction.pageC(id, action);
  }
}
