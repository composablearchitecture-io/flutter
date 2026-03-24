part of 'main.dart';

class PageARouteState {
  final int count;

  PageARouteState(this.count);

  PageARouteState copyWith({int? count}) =>
      PageARouteState(count ?? this.count);
}

class PageAState {
  final int globalCount;
  final int count;

  PageAState(this.globalCount, this.count);

  int get totalCount => globalCount + count;

  PageAState copyWith({int? globalCount, int? count}) => PageAState(
      globalCount ?? this.globalCount, count ?? this.count);
}

sealed class PageAAction {
  const PageAAction();
  const factory PageAAction.increment() = PageAActionIncrement;
  const factory PageAAction.navigate() = PageAActionNavigate;
  const factory PageAAction.incrementGlobal() = PageAActionIncrementGlobal;
}

class PageAActionIncrement extends PageAAction {
  const PageAActionIncrement() : super();
}

class PageAActionNavigate extends PageAAction {
  const PageAActionNavigate() : super();
}

class PageAActionIncrementGlobal extends PageAAction {
  const PageAActionIncrementGlobal() : super();
}

class PageAEnvironment {}

class PageA extends Routable<AppState, PageARouteState, PageAState, AppAction,
    PageAAction, AppEnvironment, PageAEnvironment> {
  RouteLens<AppState, PageARouteState, PageAState?> get routeLens => (
        get: (appState, routeState) => buildLocalState(appState, routeState),
        set: (appState, routeState, localState) => localState == null
            ? (appState, routeState)
            : setBackFromLocalState(appState, routeState, localState),
      );

  Prism<AppAction, PageAAction, RouteID> get actionPrism => (
        extract: (globalAction) => extractAction(globalAction),
        embed: (routeID, localAction) => toAppAction(routeID, localAction),
      );

  @override
  Widget build(BuildContext context, Store<PageAState, PageAAction> store,
      NestedNavigator<AppState, AppAction> nestedNavigator) {
    return Scaffold(
      backgroundColor: Colors.amber,
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
                store.send(const PageAAction.incrementGlobal());
              },
              child: const Text('Increment Global',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            TextButton(
              onPressed: () {
                debugPrint("${DateTime.now()} Button Tapped");
                store.send(const PageAAction.increment());
              },
              child: const Text('Increment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            TextButton(
              onPressed: () {
                store.send(const PageAAction.navigate());
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
  PageAEnvironment buildLocalEnvironment(AppEnvironment env) => env.pageA;

  @override
  PageAState buildLocalState(AppState appState, PageARouteState routeState) {
    return PageAState(appState.count, routeState.count);
  }

  @override
  (RouteID, PageAAction)? extractAction(AppAction action) =>
      action is AppActionPageA ? (action.id, action.action) : null;
  @override
  // TODO: implement id
  RouteID id(PageARouteState routeState) => "pageA";

  @override
  Reducer<AppState, AppAction, AppEnvironment> reducer() =>
      Reducer<PageAState, PageAAction, PageAEnvironment>.transform(
        (state, action, env) => switch (action) {
          PageAActionIncrement _ =>
            state.copyWith(count: state.count + 1),
          PageAActionIncrementGlobal _ => state,
          _ => state,
        },
      ).pullbackRoute<AppState, PageARouteState, AppAction, AppEnvironment>(
        routerStateLens: AppStateLens.navigation,
        routeLens: routeLens,
        actionPrism: actionPrism,
        toLocalEnvironment: buildLocalEnvironment,
      );

  @override
  (AppState, PageARouteState) setBackFromLocalState(
    AppState appState,
    PageARouteState routeState,
    PageAState localState,
  ) {
    return (
      appState,
      routeState.copyWith(count: localState.count),
    );
  }

  @override
  AppAction toAppAction(RouteID id, PageAAction action) {
    return AppAction.pageA(id, action);
  }
}
