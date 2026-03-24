import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';

class RouterEnvironment<AppState, AppAction> {
  final List<ComposableRouteBinding<AppState, AppAction>> bindings;
  final List<ComposableRouteRule<AppState, AppAction>> rules;
  final Store<AppState, AppAction> Function() store;
  final Function(Uri url)? openExternalUrl;

  RouterEnvironment({
    required this.store,
    required this.bindings,
    required this.rules,
    this.openExternalUrl,
  });
}

extension RouterEnvironmentImpl<AppState, AppAction> on RouterEnvironment<AppState, AppAction> {
  (Uri location, List<RouteWithApp<AppState, AppAction>>) resolver(
    AppState state,
    Uri location,
  ) {
    return _resolverWithRulesAndBindings(state, rules, bindings, location);
  }

  (Uri location, List<RouteWithApp<AppState, AppAction>>)? pop(
      RouterState<AppState, AppAction> currentState, AppState appState) {
    final binding = _bindingForLocation(currentState.location);
    final result = binding.$1.onPop?.call(appState, currentState.location, binding.$2) ??
        OnPopResult<AppState, AppAction>.system();
    switch (result) {
      case PopOnPopResultRedirect<AppState, AppAction> redirect:
        return resolver(appState, Uri.parse(redirect.location));
      case PopOnPopResultSystem<AppState, AppAction> _:
        SystemNavigator.pop();
        return null;
      case PopOnPopResultPrevent<AppState, AppAction> _:
        return null;
    }
  }

  void _openExternalUrl(Uri uri) {
    openExternalUrl?.call(uri);
  }

  (Uri location, List<RouteWithApp<AppState, AppAction>>) _resolverWithRulesAndBindings(
    AppState state,
    List<ComposableRouteRule<AppState, AppAction>> rules,
    List<ComposableRouteBinding<AppState, AppAction>> bindings,
    Uri path,
  ) {
    if (path.hasScheme && path.isAbsolute && Uri.base.host != path.host) {
      _openExternalUrl(path);
    }
    final allPaths = bindings.map((binding) => binding.patternRegExp).toList();
    for (final rule in rules) {
      final pathParams = rule.binder(path, allPaths);
      if (pathParams != null) {
        final result = rule.handler(state, path, pathParams);

        if (result is RouteRuleResultDeny<AppState, AppAction>) {
          return _resolverWithRulesAndBindings(state, rules, bindings, Uri.parse(result.redirectTo));
        } else if (result is RouteRuleResultForceAllow<AppState, AppAction>) {
          break;
        }
      }
    }
    for (final binding in bindings) {
      final pathParams = tryBinding(binding.patternRegExp, Uri.decodeFull(path.toString()));
      if (pathParams != null) {
        try {
          final result = binding.resolver(state, path, pathParams);
          return _mapRouteBindingResult(result, state, rules, bindings, path);
        } catch (e, stackTrace) {
          debugPrint('[NAV] Route resolver error for $path: $e\n$stackTrace');
          final onError = binding.onFailure?.call(state, path, pathParams, e);
          if (onError != null) return _mapRouteBindingResult(onError, state, rules, bindings, path);
          final catcher = bindings.where((binding) => binding.patternRegExp.hasMatch(kFailureRoutePath)).firstOrNull;
          if (catcher != null) {
            final result = catcher.resolver(state, path, pathParams);
            return _mapRouteBindingResult(result, state, rules, bindings, path);
          }
          throw Exception(
            '[Navigator] An unhandled error occurred in resolver for path: $path, consider adding a failure binding to catch all the failure in routing, using [ComposableRouteBinding.failure]',
          );
        }
      }
    }
    final unknown = bindings.where((binding) => binding.patternRegExp.hasMatch(kUnknownRoutePath)).firstOrNull;
    if (unknown != null) {
      final result = unknown.resolver(state, path, {});
      return _mapRouteBindingResult(result, state, rules, bindings, path);
    }
    throw Exception(
      '[Navigator] No binding found for path: $path, consider adding an unknown binding to catch all the unhandled paths, using [ComposableRouteBinding.unknown]',
    );
  }

  _mapRouteBindingResult(
    RouteBindingResult<AppState, AppAction> result,
    AppState state,
    List<ComposableRouteRule<AppState, AppAction>> rules,
    List<ComposableRouteBinding<AppState, AppAction>> bindings,
    Uri path,
  ) {
    switch (result) {
      case RouteBindingResultMatched<AppState, AppAction> match:
        return (path, match.routes);
      case RouteBindingResultRedirect<AppState, AppAction> redirect:
        return _resolverWithRulesAndBindings(state, rules, bindings, Uri.parse(redirect.location));
    }
  }

  (ComposableRouteBinding<AppState, AppAction>, Map<String, String>) _bindingForLocation(Uri location) {
    for (final binding in bindings) {
      final pathParams = tryBinding(binding.patternRegExp, location.toString());
      if (pathParams != null) {
        return (binding, pathParams);
      }
    }
    final unknown = bindings.where((binding) => binding.patternRegExp.hasMatch(kUnknownRoutePath)).firstOrNull;
    if (unknown != null) {
      return (unknown, {});
    }
    throw Exception(
      '[Navigator] No binding found for path: $location, consider adding an unknown binding to catch all the unhandled paths, using [ComposableRouteBinding.unknown]',
    );
  }
}
