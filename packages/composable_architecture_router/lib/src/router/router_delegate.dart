import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';
import 'package:composable_architecture_router/src/router/router_builder.dart';

class ComposableRouterDelegate<AppState, AppAction>
    extends RouterDelegate<RouterState<AppState, AppAction>>
    with ChangeNotifier {
  /// Called by the [Router] when it detects a route information may have
  /// changed as a result of rebuild.
  ///
  /// If this getter returns non-null, the [Router] will start to report new
  /// route information back to the engine. In web applications, the new
  /// route information is used for populating browser history in order to
  /// support the forward and the backward buttons.
  ///
  /// When overriding this method, the configuration returned by this getter
  /// must be able to construct the current app state and build the widget
  /// with the same configuration in the [build] method if it is passed back
  /// to the [setNewRoutePath]. Otherwise, the browser backward and forward
  /// buttons will not work properly.
  ///
  /// By default, this getter returns null, which prevents the [Router] from
  /// reporting the route information. To opt in, a subclass can override this
  /// getter to return the current configuration.
  ///
  /// At most one [Router] can opt in to route information reporting. Typically,
  /// only the top-most [Router] created by [WidgetsApp.router] should opt for
  /// route information reporting.
  ///
  /// ## State Restoration
  ///
  /// This getter is also used by the [Router] to implement state restoration.
  /// During state serialization, the [Router] will persist the current
  /// configuration and during state restoration pass it back to the delegate
  /// by calling [setRestoredRoutePath].
  @override
  RouterState<AppState, AppAction>? currentConfiguration;

  final GlobalKey<NavigatorState> _mainNavigatorKey =
      GlobalKey<NavigatorState>();

  final Store<AppState, AppAction> appStore;
  final RouterState<AppState, AppAction> Function(AppState) toNavigatorState;
  final AppAction Function(RouterAction<AppState, AppAction>) fromRouterAction;
  final Store<RouterState<AppState, AppAction>,
      RouterAction<AppState, AppAction>> store;
  late final RouterBuilder builder;

  ComposableRouterDelegate({
    required this.appStore,
    required this.toNavigatorState,
    required this.fromRouterAction,
    RouterBuilder? customBuilder,
  })  : store = appStore.scope(
            toLocalState: toNavigatorState, toGlobalAction: fromRouterAction),
        super() {
    currentConfiguration = store.state;
    builder = customBuilder ??
        RouterBuilder.standard(
          didPop: (route, result) {
            final store = appStore.scope(
              toLocalState: toNavigatorState,
              toGlobalAction: fromRouterAction,
            );
            if (store.state.count > 1) {
              store.send(RouterAction<AppState, AppAction>.pop());
              return true;
            } else {
              return false;
            }
          },
        );
    store.stateObservable
        .distinct((prev, next) => prev.location == next.location)
        .listen(
      (state) {
        currentConfiguration = state;
        notifyListeners();
      },
    );
  }

  /// Called by the [Router] when the [Router.routeInformationProvider] reports that a
  /// new route has been pushed to the application by the operating system.
  ///
  /// Consider using a [SynchronousFuture] if the result can be computed
  /// synchronously, so that the [Router] does not need to wait for the next
  /// microtask to schedule a build.
  @override
  Future<void> setNewRoutePath(RouterState<AppState, AppAction> configuration) {
    store.send(RouterAction<AppState, AppAction>.reset(configuration));
    return SynchronousFuture<void>(null);
  }

  /// Called by the [Router] when the [Router.backButtonDispatcher] reports that
  /// the operating system is requesting that the current route be popped.
  ///
  /// The method should return a boolean [Future] to indicate whether this
  /// delegate handles the request. Returning false will cause the entire app
  /// to be popped.
  ///
  /// Consider using a [SynchronousFuture] if the result can be computed
  /// synchronously, so that the [Router] does not need to wait for the next
  /// microtask to schedule a build.
  @override
  Future<bool> popRoute() {
    if (store.state.count > 1) {
      // TODO: handle pop
      return SynchronousFuture<bool>(true);
    }
    return SynchronousFuture<bool>(false);
  }

  /// Called by the [Router] to obtain the widget tree that represents the
  /// current state.
  ///
  /// This is called whenever the [Future]s returned by [setInitialRoutePath],
  /// [setNewRoutePath], or [setRestoredRoutePath] complete as well as when this
  /// notifies its clients (see the [Listenable] interface, which this interface
  /// includes). In addition, it may be called at other times. It is important,
  /// therefore, that the methods above do not update the state that the [build]
  /// method uses before they complete their respective futures.
  ///
  /// Typically this method returns a suitably-configured [Navigator]. If you do
  /// plan to create a navigator, consider using the
  /// [PopNavigatorRouterDelegateMixin]. If state restoration is enabled for the
  /// [Router] using this delegate, consider providing a non-null
  /// [Navigator.restorationScopeId] to the [Navigator] returned by this method.
  ///
  /// This method must not return null.
  ///
  /// The `context` is the [Router]'s build context.
  @override
  Widget build(BuildContext context) {
    return builder.build(
      context,
      _mainNavigatorKey,
      store.state.pages(appStore, toNavigatorState, builder, context),
    );
  }
}
