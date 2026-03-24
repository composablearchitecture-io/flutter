import 'package:composable_architecture_router/composable_architecture_router.dart';

const kFailureRoutePath = '__failure__';
const kUnknownRoutePath = '__unknown__';

class ComposableRouteBinding<AppState, AppAction> {
  final RegExp patternRegExp;
  final RouteBindingResolver<AppState, AppAction> resolver;
  final RouteFailureHandler<AppState, AppAction>? onFailure;
  final RouteOnPopHandler<AppState, AppAction>? onPop;

  ComposableRouteBinding({
    required this.patternRegExp,
    required this.resolver,
    this.onPop,
    this.onFailure,
  });

  factory ComposableRouteBinding.unknown(RouteBindingResolver<AppState, AppAction> resolver,
          {RouteOnPopHandler<AppState, AppAction>? onPop}) =>
      ComposableRouteBinding<AppState, AppAction>(
        patternRegExp: RegExp(kUnknownRoutePath),
        resolver: resolver,
        onPop: onPop,
      );

  factory ComposableRouteBinding.failure(RouteBindingResolver<AppState, AppAction> resolver,
          {RouteOnPopHandler<AppState, AppAction>? onPop}) =>
      ComposableRouteBinding<AppState, AppAction>(
        patternRegExp: RegExp(kFailureRoutePath),
        resolver: resolver,
        onPop: onPop,
      );

  factory ComposableRouteBinding.match(
    String path,
    List<RouteWithApp<AppState, AppAction>> Function(
      AppState state,
      Uri location,
      Map<String, String> pathParams,
    ) match, {
    RouteOnPopHandler<AppState, AppAction>? onPop,
    RouteFailureHandler<AppState, AppAction>? onFailure,
  }) =>
      ComposableRouteBinding<AppState, AppAction>(
        patternRegExp: path.pathTemplateRegex,
        resolver: (appState, location, pathParams) => RouteBindingResult.matched(match(appState, location, pathParams)),
        onPop: onPop,
        onFailure: onFailure,
      );

  factory ComposableRouteBinding.matchOne(
    String path,
    RouteWithApp<AppState, AppAction> Function(
      AppState state,
      Uri location,
      Map<String, String> pathParams,
    ) match, {
    RouteOnPopHandler<AppState, AppAction>? onPop,
    RouteFailureHandler<AppState, AppAction>? onFailure,
  }) =>
      ComposableRouteBinding<AppState, AppAction>(
        patternRegExp: path.pathTemplateRegex,
        resolver: (appState, location, pathParams) => RouteBindingResult.matched(
          [match(appState, location, pathParams)],
        ),
        onPop: onPop,
        onFailure: onFailure,
      );

  factory ComposableRouteBinding.redirect({required String from, required String to}) =>
      ComposableRouteBinding<AppState, AppAction>(
        patternRegExp: from.pathTemplateRegex,
        resolver: (state, location, pathParameters) => RouteBindingResult.redirect(to),
      );

  factory ComposableRouteBinding.deepLinkFrom({required RegExp pattern}) => ComposableRouteBinding<AppState, AppAction>(
        patternRegExp: pattern,
        resolver: (state, location, pathParameters) => RouteBindingResult.redirect(location.path),
      );
}

sealed class RouteBindingResult<AppState, AppAction> {
  const RouteBindingResult();

  const factory RouteBindingResult.matched(
    List<RouteWithApp<AppState, AppAction>> routes,
  ) = RouteBindingResultMatched<AppState, AppAction>;

  const factory RouteBindingResult.redirect(
    String location,
  ) = RouteBindingResultRedirect<AppState, AppAction>;
}

class RouteBindingResultMatched<AppState, AppAction> extends RouteBindingResult<AppState, AppAction> {
  final List<RouteWithApp<AppState, AppAction>> routes;

  const RouteBindingResultMatched(this.routes);
}

class RouteBindingResultRedirect<AppState, AppAction> extends RouteBindingResult<AppState, AppAction> {
  final String location;

  const RouteBindingResultRedirect(this.location);
}

sealed class OnPopResult<AppState, AppAction> {
  const OnPopResult._();

  const factory OnPopResult.prevent() = PopOnPopResultPrevent<AppState, AppAction>;

  const factory OnPopResult.system() = PopOnPopResultSystem<AppState, AppAction>;

  const factory OnPopResult.redirect(String location) = PopOnPopResultRedirect<AppState, AppAction>;
}

class PopOnPopResultPrevent<AppState, AppAction> extends OnPopResult<AppState, AppAction> {
  const PopOnPopResultPrevent() : super._();
}

class PopOnPopResultSystem<AppState, AppAction> extends OnPopResult<AppState, AppAction> {
  const PopOnPopResultSystem() : super._();
}

class PopOnPopResultRedirect<AppState, AppAction> extends OnPopResult<AppState, AppAction> {
  final String location;

  const PopOnPopResultRedirect(this.location) : super._();
}
