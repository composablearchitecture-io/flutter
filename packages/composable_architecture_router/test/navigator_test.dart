import 'package:composable_architecture_router/composable_architecture_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouterAction', () {
    test('navigate creates RouterActionNavigate', () {
      const action = RouterAction<int, String>.navigate('/home');
      expect(action, isA<RouterActionNavigate<int, String>>());
      final navigate = action as RouterActionNavigate<int, String>;
      expect(navigate.path, '/home');
      expect(navigate.queryParams, isNull);
    });

    test('navigate with queryParams', () {
      const action = RouterAction<int, String>.navigate('/search',
          queryParams: {'q': 'test', 'page': '1'});
      final navigate = action as RouterActionNavigate<int, String>;
      expect(navigate.path, '/search');
      expect(navigate.queryParams, {'q': 'test', 'page': '1'});
    });

    test('pop creates RouterActionPop', () {
      const action = RouterAction<int, String>.pop();
      expect(action, isA<RouterActionPop<int, String>>());
    });

    test('reset creates RouterActionReset', () {
      final state = RouterState<int, String>.initial();
      final action = RouterAction<int, String>.reset(state);
      expect(action, isA<RouterActionReset<int, String>>());
      expect((action as RouterActionReset).state, same(state));
    });

    test('routeChanged creates RouterActionRouteChanged', () {
      final prev = RouterState<int, String>.initial();
      final curr = RouterState<int, String>.initial();
      final action = RouterAction<int, String>.routeChanged(
          previous: prev, current: curr);
      expect(action, isA<RouterActionRouteChanged<int, String>>());
      final changed = action as RouterActionRouteChanged<int, String>;
      expect(changed.previous, same(prev));
      expect(changed.current, same(curr));
    });
  });

  group('RouterActionNavigateExt', () {
    test('location without query params', () {
      const action = RouterActionNavigate<int, String>('/home');
      expect(action.location, '/home');
    });

    test('location with query params', () {
      const action = RouterActionNavigate<int, String>('/search',
          queryParams: {'q': 'hello world', 'page': '2'});
      expect(action.location, '/search?q=hello+world&page=2');
    });

    test('location with empty query params', () {
      const action =
          RouterActionNavigate<int, String>('/home', queryParams: {});
      expect(action.location, '/home');
    });
  });

  group('RouterActionUtils', () {
    test('mapEvery dispatches correctly', () {
      const action = RouterAction<int, String>.navigate('/test');
      final result = action.mapEvery(
        navigate: (n) => 'navigate:${n.path}',
        pop: (_) => 'pop',
        routeChanged: (_) => 'changed',
        reset: (_) => 'reset',
      );
      expect(result, 'navigate:/test');
    });

    test('mapAny with matching case', () {
      const action = RouterAction<int, String>.pop();
      final result = action.mapAny(
        orElse: () => 'default',
        pop: (_) => 'popped',
      );
      expect(result, 'popped');
    });

    test('mapAny falls back to orElse', () {
      const action = RouterAction<int, String>.pop();
      final result = action.mapAny(
        orElse: () => 'default',
        navigate: (_) => 'navigate',
      );
      expect(result, 'default');
    });

    test('is* getters', () {
      const nav = RouterAction<int, String>.navigate('/x');
      expect(nav.isRouterActionNavigate, isTrue);
      expect(nav.isRouterActionPop, isFalse);

      const pop = RouterAction<int, String>.pop();
      expect(pop.isRouterActionPop, isTrue);
      expect(pop.isRouterActionNavigate, isFalse);
    });

    test('nullable getters', () {
      const nav = RouterAction<int, String>.navigate('/x');
      expect(nav.navigate, isNotNull);
      expect(nav.pop, isNull);
      expect(nav.routeChanged, isNull);
      expect(nav.reset, isNull);
    });
  });

  group('RouterActionNavigate equality', () {
    test('equal with same path and no queryParams', () {
      const a = RouterActionNavigate<int, String>('/home');
      const b = RouterActionNavigate<int, String>('/home');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal with different paths', () {
      const a = RouterActionNavigate<int, String>('/home');
      const b = RouterActionNavigate<int, String>('/about');
      expect(a, isNot(equals(b)));
    });

    test('equal with same queryParams', () {
      const a = RouterActionNavigate<int, String>('/s',
          queryParams: {'q': 'test'});
      const b = RouterActionNavigate<int, String>('/s',
          queryParams: {'q': 'test'});
      expect(a, equals(b));
    });

    test('not equal with different queryParams', () {
      const a = RouterActionNavigate<int, String>('/s',
          queryParams: {'q': 'a'});
      const b = RouterActionNavigate<int, String>('/s',
          queryParams: {'q': 'b'});
      expect(a, isNot(equals(b)));
    });
  });

  group('RouterState', () {
    test('initial state', () {
      final state = RouterState<int, String>.initial();
      expect(state.location, Uri());
      expect(state.main.routes, isEmpty);
    });

    test('copyWith location', () {
      final state = RouterState<int, String>.initial();
      final newState = state.copyWith(location: Uri.parse('/home'));
      expect(newState.location, Uri.parse('/home'));
      expect(newState.main, same(state.main));
    });

    test('copyWith main', () {
      final state = RouterState<int, String>.initial();
      final newMain = StackNavigator<int, String>([]);
      final newState = state.copyWith(main: newMain);
      expect(newState.main, same(newMain));
      expect(newState.location, state.location);
    });

    test('equality based on location', () {
      final a = RouterState<int, String>(Uri.parse('/home'), StackNavigator([]));
      final b = RouterState<int, String>(Uri.parse('/home'), StackNavigator([]));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different location', () {
      final a = RouterState<int, String>(Uri.parse('/home'), StackNavigator([]));
      final b =
          RouterState<int, String>(Uri.parse('/about'), StackNavigator([]));
      expect(a, isNot(equals(b)));
    });

    test('toJson and fromJson roundtrip preserves location', () {
      final state =
          RouterState<int, String>(Uri.parse('/home'), StackNavigator([]));
      final json = state.toJson();
      final restored = RouterState.fromJson<int, String>(json);
      expect(restored.location, Uri.parse('/home'));
    });

    test('toString is readable', () {
      final state =
          RouterState<int, String>(Uri.parse('/home'), StackNavigator([]));
      expect(state.toString(), contains('RouterState'));
      expect(state.toString(), contains('/home'));
    });
  });

  group('StackNavigator', () {
    test('copyWith routes', () {
      final nav = StackNavigator<int, String>([]);
      final newNav = nav.copyWith(routes: []);
      expect(newNav, isA<StackNavigator<int, String>>());
    });

    test('toString', () {
      final nav = StackNavigator<int, String>([]);
      expect(nav.toString(), 'StackNavigator(routes: 0)');
    });
  });

  group('TabNavigator', () {
    test('copyWith', () {
      final nav = TabNavigator<int, String>([StackNavigator([])], 0);
      final newNav = nav.copyWith(currentTab: 0);
      expect(newNav.currentTab, 0);
      expect(newNav.nestedNavigators.length, 1);
    });

    test('routes returns current tab routes', () {
      final tab0 = StackNavigator<int, String>([]);
      final tab1 = StackNavigator<int, String>([]);
      final nav = TabNavigator<int, String>([tab0, tab1], 1);
      expect(nav.routes, same(tab1.routes));
    });

    test('toString', () {
      final nav = TabNavigator<int, String>([StackNavigator([])], 0);
      expect(nav.toString(), contains('TabNavigator'));
    });
  });

  group('RouteBindingResult', () {
    test('matched creates RouteBindingResultMatched', () {
      final result =
          RouteBindingResult<int, String>.matched(<RouteWithApp<int, String>>[]);
      expect(result, isA<RouteBindingResultMatched<int, String>>());
      expect((result as RouteBindingResultMatched).routes, isEmpty);
    });

    test('redirect creates RouteBindingResultRedirect', () {
      const result = RouteBindingResult<int, String>.redirect('/login');
      expect(result, isA<RouteBindingResultRedirect<int, String>>());
      expect((result as RouteBindingResultRedirect).location, '/login');
    });
  });

  group('OnPopResult', () {
    test('prevent', () {
      const result = OnPopResult<int, String>.prevent();
      expect(result, isA<PopOnPopResultPrevent<int, String>>());
    });

    test('system', () {
      const result = OnPopResult<int, String>.system();
      expect(result, isA<PopOnPopResultSystem<int, String>>());
    });

    test('redirect', () {
      const result = OnPopResult<int, String>.redirect('/home');
      expect(result, isA<PopOnPopResultRedirect<int, String>>());
      expect((result as PopOnPopResultRedirect).location, '/home');
    });
  });

  group('RouteRuleResult', () {
    test('allow', () {
      const result = RouteRuleResult<int, String>.allow();
      expect(result, isA<RouteRuleResultAllow<int, String>>());
    });

    test('deny', () {
      const result = RouteRuleResult<int, String>.deny('/login');
      expect(result, isA<RouteRuleResultDeny<int, String>>());
      expect((result as RouteRuleResultDeny).redirectTo, '/login');
    });

    test('forceAllow', () {
      const result = RouteRuleResult<int, String>.forceAllow();
      expect(result, isA<RouteRuleResultForceAllow<int, String>>());
    });
  });

  group('RouteRuleResultUtils', () {
    test('mapEvery dispatches correctly', () {
      const result = RouteRuleResult<int, String>.deny('/login');
      final mapped = result.mapEvery(
        allow: (_) => 'allow',
        deny: (d) => 'deny:${d.redirectTo}',
        forceAllow: (_) => 'force',
      );
      expect(mapped, 'deny:/login');
    });

    test('is* and nullable getters', () {
      const result = RouteRuleResult<int, String>.allow();
      expect(result.isRouteRuleResultAllow, isTrue);
      expect(result.isRouteRuleResultDeny, isFalse);
      expect(result.allow, isNotNull);
      expect(result.deny, isNull);
    });
  });

  group('ComposablePageArguments', () {
    test('defaults', () {
      final args = ComposablePageArguments();
      expect(args.isFlattened, isFalse);
    });

    test('copyWith', () {
      final args = ComposablePageArguments();
      final flattened = args.copyWith(isFlattened: true);
      expect(flattened.isFlattened, isTrue);
    });

    test('equality', () {
      final a = ComposablePageArguments(isFlattened: true);
      final b = ComposablePageArguments(isFlattened: true);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality', () {
      final a = ComposablePageArguments(isFlattened: true);
      final b = ComposablePageArguments(isFlattened: false);
      expect(a, isNot(equals(b)));
    });
  });

  group('PathTemplateRegex', () {
    test('simple path matches', () {
      final regex = '/home'.pathTemplateRegex;
      expect(regex.hasMatch('/home'), isTrue);
      expect(regex.hasMatch('/about'), isFalse);
    });

    test('path with parameter', () {
      final regex = '/user/:id'.pathTemplateRegex;
      final match = regex.firstMatch('/user/123');
      expect(match, isNotNull);
      expect(match!.namedGroup('id'), '123');
    });

    test('path with constrained parameter', () {
      final regex = '/page/:id(a|b|c)'.pathTemplateRegex;
      expect(regex.hasMatch('/page/a'), isTrue);
      expect(regex.hasMatch('/page/b'), isTrue);
      expect(regex.hasMatch('/page/d'), isFalse);
    });

    test('path with multiple parameters', () {
      final regex = '/category/:catId/item/:itemId'.pathTemplateRegex;
      final match = regex.firstMatch('/category/books/item/42');
      expect(match, isNotNull);
      expect(match!.namedGroup('catId'), 'books');
      expect(match.namedGroup('itemId'), '42');
    });
  });

  group('tryBinding', () {
    test('returns params on match', () {
      final regex = '/user/:id'.pathTemplateRegex;
      final params = tryBinding(regex, '/user/abc');
      expect(params, isNotNull);
      expect(params!['id'], 'abc');
    });

    test('returns null on no match', () {
      final regex = '/user/:id'.pathTemplateRegex;
      final params = tryBinding(regex, '/other/path');
      expect(params, isNull);
    });

    test('strips query params before matching', () {
      final regex = '/search'.pathTemplateRegex;
      final params = tryBinding(regex, '/search?q=hello');
      expect(params, isNotNull);
    });
  });

  group('ComposableRouteBinding', () {
    test('match factory', () {
      final binding = ComposableRouteBinding<int, String>.match(
        '/user/:id',
        (state, location, pathParams) => [],
      );
      expect(
          tryBinding(binding.patternRegExp, '/user/123'), isNotNull);
    });

    test('redirect factory', () {
      final binding = ComposableRouteBinding<int, String>.redirect(
        from: '/old',
        to: '/new',
      );
      final params = tryBinding(binding.patternRegExp, '/old');
      expect(params, isNotNull);
      final result = binding.resolver(0, Uri.parse('/old'), params!);
      expect(result, isA<RouteBindingResultRedirect<int, String>>());
      expect((result as RouteBindingResultRedirect).location, '/new');
    });

    test('unknown factory', () {
      final binding = ComposableRouteBinding<int, String>.unknown(
        (state, location, params) =>
            RouteBindingResult.matched([]),
      );
      expect(binding.patternRegExp.hasMatch('__unknown__'), isTrue);
    });

    test('failure factory', () {
      final binding = ComposableRouteBinding<int, String>.failure(
        (state, location, params) =>
            RouteBindingResult.matched([]),
      );
      expect(binding.patternRegExp.hasMatch('__failure__'), isTrue);
    });
  });

  group('ComposableRouteRule', () {
    test('guardOn matches included paths', () {
      final rule = ComposableRouteRule<int, String>.guardOn(
        includedPaths: ['/admin/:id'],
        handler: (state, location, params) {
          return const RouteRuleResult.deny('/login');
        },
      );
      final allPaths = ['/admin/:id'.pathTemplateRegex];
      final result = rule.binder(Uri.parse('/admin/123'), allPaths);
      expect(result, isNotNull);
    });

    test('guardAll excludes specified paths', () {
      final rule = ComposableRouteRule<int, String>.guardAll(
        excludedPaths: ['/public'],
        handler: (state, location, params) {
          return const RouteRuleResult.deny('/login');
        },
      );
      final allPaths = ['/public'.pathTemplateRegex, '/private'.pathTemplateRegex];
      // Excluded path should return null
      final publicResult = rule.binder(Uri.parse('/public'), allPaths);
      expect(publicResult, isNull);
      // Non-excluded path should return params
      final privateResult = rule.binder(Uri.parse('/private'), allPaths);
      expect(privateResult, isNotNull);
    });
  });

  group('NestedNavigator', () {
    test('none creates NoNestedNavigator', () {
      const nav = NestedNavigator<int, String>.none();
      expect(nav, isA<NoNestedNavigator<int, String>>());
      expect(nav.builder, isNull);
    });
  });

  group('EnumeratedIterable', () {
    test('enumerated returns indexed entries', () {
      final items = ['a', 'b', 'c'];
      final enumerated = items.enumerated().toList();
      expect(enumerated.length, 3);
      expect(enumerated[0].key, 0);
      expect(enumerated[0].value, 'a');
      expect(enumerated[1].key, 1);
      expect(enumerated[1].value, 'b');
      expect(enumerated[2].key, 2);
      expect(enumerated[2].value, 'c');
    });

    test('enumerated on empty list', () {
      final items = <String>[];
      expect(items.enumerated().toList(), isEmpty);
    });
  });
}
