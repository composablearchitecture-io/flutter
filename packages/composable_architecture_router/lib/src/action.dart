import 'package:composable_architecture_router/src/state.dart';

sealed class RouterAction<AppState, AppAction> {
  const RouterAction();

  const factory RouterAction.navigate(
    String path, {
    Map<String, String>? queryParams,
  }) = RouterActionNavigate<AppState, AppAction>;

  const factory RouterAction.pop() = RouterActionPop<AppState, AppAction>;

  // INTERNALS
  // Do not send this action directly, it is used internally by the router, but you can catch it in your reducer

  // sent when the route stack changed
  const factory RouterAction.routeChanged({
    required RouterState<AppState, AppAction> previous,
    required RouterState<AppState, AppAction> current,
  }) = RouterActionRouteChanged<AppState, AppAction>;

  const factory RouterAction.reset(RouterState<AppState, AppAction> state) =
      RouterActionReset<AppState, AppAction>;
}

class RouterActionNavigate<AppState, AppAction>
    extends RouterAction<AppState, AppAction> {
  final String path;
  final Map<String, String>? queryParams;
  const RouterActionNavigate(this.path, {this.queryParams}) : super();

  @override
  String toString() =>
      'RouterActionNavigate(path: $path, queryParams: $queryParams)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouterActionNavigate &&
          path == other.path &&
          _mapEquals(queryParams, other.queryParams);

  @override
  int get hashCode => Object.hash(path, queryParams);
}

class RouterActionPop<AppState, AppAction>
    extends RouterAction<AppState, AppAction> {
  const RouterActionPop() : super();

  @override
  String toString() => 'RouterActionPop()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RouterActionPop;

  @override
  int get hashCode => runtimeType.hashCode;
}

class RouterActionRouteChanged<AppState, AppAction>
    extends RouterAction<AppState, AppAction> {
  final RouterState<AppState, AppAction> previous;
  final RouterState<AppState, AppAction> current;
  const RouterActionRouteChanged(
      {required this.previous, required this.current})
      : super();

  @override
  String toString() =>
      'RouterActionRouteChanged(previous: $previous, current: $current)';
}

class RouterActionReset<AppState, AppAction>
    extends RouterAction<AppState, AppAction> {
  final RouterState<AppState, AppAction> state;
  const RouterActionReset(this.state) : super();

  @override
  String toString() => 'RouterActionReset(state: $state)';
}

extension RouterActionNavigateExt on RouterActionNavigate {
  String get encodedQueryParams => queryParams == null || queryParams!.isEmpty
      ? ""
      : "?${queryParams!.entries.map((e) => "${e.key}=${Uri.encodeQueryComponent(e.value)}").join("&")}";

  String get location => "$path$encodedQueryParams";
}

extension RouterActionUtils<AppState, AppAction>
    on RouterAction<AppState, AppAction> {
  T mapEvery<T>(
          {required T Function(
                  RouterActionNavigate<AppState, AppAction> navigate)
              navigate,
          required T Function(RouterActionPop<AppState, AppAction> pop) pop,
          required T Function(
                  RouterActionRouteChanged<AppState, AppAction> routeChanged)
              routeChanged,
          required T Function(RouterActionReset<AppState, AppAction> reset)
              reset}) =>
      switch (this) {
        RouterActionNavigate<AppState, AppAction> e => navigate(e),
        RouterActionPop<AppState, AppAction> e => pop(e),
        RouterActionRouteChanged<AppState, AppAction> e => routeChanged(e),
        RouterActionReset<AppState, AppAction> e => reset(e)
      };

  T mapAny<T>(
          {required T Function() orElse,
          T Function(RouterActionNavigate<AppState, AppAction> navigate)?
              navigate,
          T Function(RouterActionPop<AppState, AppAction> pop)? pop,
          T Function(
                  RouterActionRouteChanged<AppState, AppAction> routeChanged)?
              routeChanged,
          T Function(RouterActionReset<AppState, AppAction> reset)? reset}) =>
      switch (this) {
        RouterActionNavigate<AppState, AppAction> e =>
          navigate?.call(e) ?? orElse(),
        RouterActionPop<AppState, AppAction> e => pop?.call(e) ?? orElse(),
        RouterActionRouteChanged<AppState, AppAction> e =>
          routeChanged?.call(e) ?? orElse(),
        RouterActionReset<AppState, AppAction> e => reset?.call(e) ?? orElse()
      };

  T? mapAnyOrNull<T>(
          {T? Function()? orElse,
          T? Function(RouterActionNavigate<AppState, AppAction> navigate)?
              navigate,
          T? Function(RouterActionPop<AppState, AppAction> pop)? pop,
          T? Function(
                  RouterActionRouteChanged<AppState, AppAction> routeChanged)?
              routeChanged,
          T? Function(RouterActionReset<AppState, AppAction> reset)? reset}) =>
      switch (this) {
        RouterActionNavigate<AppState, AppAction> e =>
          navigate?.call(e) ?? orElse?.call(),
        RouterActionPop<AppState, AppAction> e =>
          pop?.call(e) ?? orElse?.call(),
        RouterActionRouteChanged<AppState, AppAction> e =>
          routeChanged?.call(e) ?? orElse?.call(),
        RouterActionReset<AppState, AppAction> e =>
          reset?.call(e) ?? orElse?.call()
      };

  void onEvery(
          {required Function(RouterActionNavigate<AppState, AppAction> navigate)
              navigate,
          required Function(RouterActionPop<AppState, AppAction> pop) pop,
          required Function(
                  RouterActionRouteChanged<AppState, AppAction> routeChanged)
              routeChanged,
          required Function(RouterActionReset<AppState, AppAction> reset)
              reset}) =>
      switch (this) {
        RouterActionNavigate<AppState, AppAction> e => navigate(e),
        RouterActionPop<AppState, AppAction> e => pop(e),
        RouterActionRouteChanged<AppState, AppAction> e => routeChanged(e),
        RouterActionReset<AppState, AppAction> e => reset(e)
      };

  void onAny(
          {Function()? orElse,
          Function(RouterActionNavigate<AppState, AppAction> navigate)?
              navigate,
          Function(RouterActionPop<AppState, AppAction> pop)? pop,
          Function(RouterActionRouteChanged<AppState, AppAction> routeChanged)?
              routeChanged,
          Function(RouterActionReset<AppState, AppAction> reset)? reset}) =>
      switch (this) {
        RouterActionNavigate<AppState, AppAction> e =>
          navigate?.call(e) ?? orElse?.call(),
        RouterActionPop<AppState, AppAction> e =>
          pop?.call(e) ?? orElse?.call(),
        RouterActionRouteChanged<AppState, AppAction> e =>
          routeChanged?.call(e) ?? orElse?.call(),
        RouterActionReset<AppState, AppAction> e =>
          reset?.call(e) ?? orElse?.call()
      };

  bool get isRouterActionNavigate =>
      this is RouterActionNavigate<AppState, AppAction>;
  bool get isRouterActionPop => this is RouterActionPop<AppState, AppAction>;
  bool get isRouterActionRouteChanged =>
      this is RouterActionRouteChanged<AppState, AppAction>;
  bool get isRouterActionReset =>
      this is RouterActionReset<AppState, AppAction>;

  RouterActionNavigate<AppState, AppAction>? get navigate =>
      this is RouterActionNavigate<AppState, AppAction>
          ? (this as RouterActionNavigate<AppState, AppAction>)
          : null;
  RouterActionPop<AppState, AppAction>? get pop =>
      this is RouterActionPop<AppState, AppAction>
          ? (this as RouterActionPop<AppState, AppAction>)
          : null;
  RouterActionRouteChanged<AppState, AppAction>? get routeChanged =>
      this is RouterActionRouteChanged<AppState, AppAction>
          ? (this as RouterActionRouteChanged<AppState, AppAction>)
          : null;
  RouterActionReset<AppState, AppAction>? get reset =>
      this is RouterActionReset<AppState, AppAction>
          ? (this as RouterActionReset<AppState, AppAction>)
          : null;
}

bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
