part of 'index.dart';

class CupertinoPageComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction>
    extends PageComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> {
  @override
  const CupertinoPageComposableRoute(super.routable, super.state, {super.nested, super.options});

  @override
  CupertinoPageComposableRoute<AppState, RouteState, LocalState, AppAction, LocalAction> copyWith({
    RouteState? state,
    ListOfRoutesWithApp<AppState, AppAction>? nested,
    PageOptions? options,
  }) =>
      CupertinoPageComposableRoute(routable, state ?? this.state,
          nested: nested ?? this.nested, options: options ?? this.options);

  @override
  Route<void> buildRoute(
    BuildContext context,
    Widget Function(BuildContext context) builder,
    Page page,
  ) {
    return CupertinoPageRoute(
      builder: builder,
      settings: page,
    );
  }
}
