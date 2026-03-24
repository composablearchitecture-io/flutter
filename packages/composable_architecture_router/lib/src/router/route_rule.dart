import 'package:composable_architecture_router/composable_architecture_router.dart';

class ComposableRouteRule<AppState, AppAction> {
  final RouteRuleHandler<AppState, AppAction> handler;
  final Map<String, String>? Function(Uri location, List<RegExp> allPaths)
      binder;

  ComposableRouteRule._({
    required this.handler,
    required this.binder,
  });

  factory ComposableRouteRule.guardOn({
    required List<String> includedPaths,
    List<RegExp>? includedPathRegexes,
    required RouteRuleHandler<AppState, AppAction> handler,
  }) =>
      ComposableRouteRule<AppState, AppAction>._(
        handler: handler,
        binder: _binderIncluding([
          ...includedPaths
              .map((e) => e.pathTemplateRegex)
              .toList(growable: false),
          if (includedPathRegexes != null) ...includedPathRegexes,
        ]),
      );

  factory ComposableRouteRule.guardAll({
    required List<String> excludedPaths,
    List<RegExp>? excludedPathRegexes,
    required RouteRuleHandler<AppState, AppAction> handler,
  }) =>
      ComposableRouteRule<AppState, AppAction>._(
        handler: handler,
        binder: _binderExcluding([
          ...excludedPaths
              .map((e) => e.pathTemplateRegex)
              .toList(growable: false),
          if (excludedPathRegexes != null) ...excludedPathRegexes,
        ]),
      );

  factory ComposableRouteRule.guardWhen({
    required Map<String, String>? Function(Uri location, List<RegExp> allPaths)
        bindsTo,
    required RouteRuleHandler<AppState, AppAction> handler,
  }) =>
      ComposableRouteRule<AppState, AppAction>._(
        handler: handler,
        binder: bindsTo,
      );

  static Map<String, String>? Function(Uri location, List<RegExp> allPaths)
      _binderIncluding(List<RegExp> includedPaths) => (location, allPaths) {
            final decoded = Uri.decodeFull(location.toString());
            for (final path in includedPaths) {
              final bind = tryBinding(path, decoded);
              if (bind != null) {
                return bind;
              }
            }
            return null;
          };

  static Map<String, String>? Function(Uri location, List<RegExp> allPaths)
      _binderExcluding(List<RegExp> excludedPaths) => (location, allPaths) {
            final decoded = Uri.decodeFull(location.toString());
            for (final path in excludedPaths) {
              final bind = tryBinding(path, decoded);
              if (bind != null) {
                return null;
              }
            }
            return _binderIncluding(allPaths)(location, allPaths);
          };
}

sealed class RouteRuleResult<AppState, AppAction> {
  const RouteRuleResult();

  const factory RouteRuleResult.allow() =
      RouteRuleResultAllow<AppState, AppAction>;

  const factory RouteRuleResult.deny(
    String redirectTo,
  ) = RouteRuleResultDeny<AppState, AppAction>;

  const factory RouteRuleResult.forceAllow() =
      RouteRuleResultForceAllow<AppState, AppAction>;
}

class RouteRuleResultAllow<AppState, AppAction>
    extends RouteRuleResult<AppState, AppAction> {
  const RouteRuleResultAllow() : super();
}

class RouteRuleResultDeny<AppState, AppAction>
    extends RouteRuleResult<AppState, AppAction> {
  final String redirectTo;
  const RouteRuleResultDeny(this.redirectTo) : super();
}

class RouteRuleResultForceAllow<AppState, AppAction>
    extends RouteRuleResult<AppState, AppAction> {
  const RouteRuleResultForceAllow() : super();
}

extension RouteRuleResultUtils<AppState, AppAction>
    on RouteRuleResult<AppState, AppAction> {
  T mapEvery<T>(
          {required T Function(RouteRuleResultAllow<AppState, AppAction> allow)
              allow,
          required T Function(RouteRuleResultDeny<AppState, AppAction> deny)
              deny,
          required T Function(
                  RouteRuleResultForceAllow<AppState, AppAction> forceAllow)
              forceAllow}) =>
      switch (this) {
        RouteRuleResultAllow<AppState, AppAction> e => allow(e),
        RouteRuleResultDeny<AppState, AppAction> e => deny(e),
        RouteRuleResultForceAllow<AppState, AppAction> e => forceAllow(e)
      };

  T mapAny<T>(
          {required T Function() orElse,
          T Function(RouteRuleResultAllow<AppState, AppAction> allow)? allow,
          T Function(RouteRuleResultDeny<AppState, AppAction> deny)? deny,
          T Function(RouteRuleResultForceAllow<AppState, AppAction> forceAllow)?
              forceAllow}) =>
      switch (this) {
        RouteRuleResultAllow<AppState, AppAction> e =>
          allow?.call(e) ?? orElse(),
        RouteRuleResultDeny<AppState, AppAction> e => deny?.call(e) ?? orElse(),
        RouteRuleResultForceAllow<AppState, AppAction> e =>
          forceAllow?.call(e) ?? orElse()
      };

  T? mapAnyOrNull<T>(
          {T? Function()? orElse,
          T? Function(RouteRuleResultAllow<AppState, AppAction> allow)? allow,
          T? Function(RouteRuleResultDeny<AppState, AppAction> deny)? deny,
          T? Function(
                  RouteRuleResultForceAllow<AppState, AppAction> forceAllow)?
              forceAllow}) =>
      switch (this) {
        RouteRuleResultAllow<AppState, AppAction> e =>
          allow?.call(e) ?? orElse?.call(),
        RouteRuleResultDeny<AppState, AppAction> e =>
          deny?.call(e) ?? orElse?.call(),
        RouteRuleResultForceAllow<AppState, AppAction> e =>
          forceAllow?.call(e) ?? orElse?.call()
      };

  void onEvery(
          {required Function(RouteRuleResultAllow<AppState, AppAction> allow)
              allow,
          required Function(RouteRuleResultDeny<AppState, AppAction> deny) deny,
          required Function(
                  RouteRuleResultForceAllow<AppState, AppAction> forceAllow)
              forceAllow}) =>
      switch (this) {
        RouteRuleResultAllow<AppState, AppAction> e => allow(e),
        RouteRuleResultDeny<AppState, AppAction> e => deny(e),
        RouteRuleResultForceAllow<AppState, AppAction> e => forceAllow(e)
      };

  void onAny(
          {Function()? orElse,
          Function(RouteRuleResultAllow<AppState, AppAction> allow)? allow,
          Function(RouteRuleResultDeny<AppState, AppAction> deny)? deny,
          Function(RouteRuleResultForceAllow<AppState, AppAction> forceAllow)?
              forceAllow}) =>
      switch (this) {
        RouteRuleResultAllow<AppState, AppAction> e =>
          allow?.call(e) ?? orElse?.call(),
        RouteRuleResultDeny<AppState, AppAction> e =>
          deny?.call(e) ?? orElse?.call(),
        RouteRuleResultForceAllow<AppState, AppAction> e =>
          forceAllow?.call(e) ?? orElse?.call()
      };

  bool get isRouteRuleResultAllow =>
      this is RouteRuleResultAllow<AppState, AppAction>;
  bool get isRouteRuleResultDeny =>
      this is RouteRuleResultDeny<AppState, AppAction>;
  bool get isRouteRuleResultForceAllow =>
      this is RouteRuleResultForceAllow<AppState, AppAction>;

  RouteRuleResultAllow<AppState, AppAction>? get allow =>
      this is RouteRuleResultAllow<AppState, AppAction>
          ? (this as RouteRuleResultAllow<AppState, AppAction>)
          : null;
  RouteRuleResultDeny<AppState, AppAction>? get deny =>
      this is RouteRuleResultDeny<AppState, AppAction>
          ? (this as RouteRuleResultDeny<AppState, AppAction>)
          : null;
  RouteRuleResultForceAllow<AppState, AppAction>? get forceAllow =>
      this is RouteRuleResultForceAllow<AppState, AppAction>
          ? (this as RouteRuleResultForceAllow<AppState, AppAction>)
          : null;
}
