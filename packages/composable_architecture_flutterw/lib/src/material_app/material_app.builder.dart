part of 'material_app.dart';

/// A [MaterialApp.router] wrapper that integrates with a [Store].
///
/// Observes [MaterialAppState] from your app state and automatically
/// rebuilds when locale or brightness changes. Optionally listens to
/// platform events (locale changes, brightness, app lifecycle, etc.)
/// via the [observer] mixin.
///
/// ## Example
///
/// ```dart
/// import 'package:composable_architecture_flutterw/material.dart';
///
/// ComposableMaterialApp<AppState, AppAction>(
///   title: 'My App',
///   store: appStore,
///   toMaterialAppState: (state) => state.materialAppState,
///   toThemeData: (appState) => ThemeData(brightness: appState.brightness),
///   routerConfig: routerConfig,
/// );
/// ```
class ComposableMaterialApp<AppState, AppAction> extends StatefulWidget {
  /// The title passed to [MaterialApp].
  final String title;

  /// The application store.
  final Store<AppState, AppAction> store;

  /// Maps [MaterialAppState] to a [ThemeData] for theming.
  final ThemeData Function(MaterialAppState appState)? toThemeData;

  /// Projects [MaterialAppState] from the application state.
  final MaterialAppState Function(AppState) toMaterialAppState;

  /// Supported locales passed to [MaterialApp].
  final Iterable<Locale> supportedLocales;

  /// Localization delegates passed to [MaterialApp].
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// Optional mixin that maps platform events to store actions.
  final WidgetBindingReducer<AppAction>? observer;

  /// Router configuration for [MaterialApp.router].
  final RouterConfig<Object>? routerConfig;

  /// Optional builder wrapping the [MaterialApp]'s navigator.
  final Widget Function(BuildContext, Widget?)? builder;

  /// Locale list resolution callback.
  final LocaleListResolutionCallback? localeListResolutionCallback;

  /// Locale resolution callback.
  final LocaleResolutionCallback? localeResolutionCallback;

  /// Called after the first frame is rendered.
  final Function()? onAppStart;

  /// Creates a [ComposableMaterialApp].
  const ComposableMaterialApp({
    super.key,
    required this.title,
    required this.store,
    required this.toMaterialAppState,
    this.routerConfig,
    this.builder,
    this.observer,
    this.localizationsDelegates,
    this.toThemeData,
    this.supportedLocales = const [Locale('en')],
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.onAppStart,
  });

  @override
  State<ComposableMaterialApp<AppState, AppAction>> createState() => _ComposableMaterialAppState<AppState, AppAction>();
}

class _ComposableMaterialAppState<AppState, AppAction> extends State<ComposableMaterialApp<AppState, AppAction>>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onAppStart?.call();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    var action = widget.observer?.didChangeLocales(locales);
    if (action != null) {
      widget.store.send(action);
    }
  }

  @override
  void didChangePlatformBrightness() {
    var action = widget.observer?.didChangePlatformBrightness(
      View.of(context).platformDispatcher.platformBrightness,
    );
    if (action != null) {
      widget.store.send(action);
    }
  }

  @override
  void didChangeAccessibilityFeatures() {
    var action = widget.observer?.didChangeAccessibilityFeatures();
    if (action != null) {
      widget.store.send(action);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    var action = widget.observer?.didChangeAppLifecycleState(state);
    if (action != null) {
      widget.store.send(action);
    }
  }

  @override
  void didChangeMetrics() {
    var action = widget.observer?.didChangeMetrics();
    if (action != null) {
      widget.store.send(action);
    }
  }

  @override
  void didChangeTextScaleFactor() {
    var action = widget.observer?.didChangeTextScaleFactor();
    if (action != null) {
      widget.store.send(action);
    }
  }

  @override
  void didHaveMemoryPressure() {
    var action = widget.observer?.didHaveMemoryPressure();
    if (action != null) {
      widget.store.send(action);
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    var action = widget.observer?.didRequestAppExit();
    if (action != null) {
      widget.store.send(action);
      return Future.value(AppExitResponse.cancel);
    } else {
      return super.didRequestAppExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WithStore.observe(
      store: widget.store,
      observe: widget.toMaterialAppState,
      builder: (state, send, context) => MaterialApp.router(
        title: widget.title,
        builder: widget.builder,
        theme: widget.toThemeData?.call(state),
        locale: state.locale,
        supportedLocales: widget.supportedLocales,
        localizationsDelegates: widget.localizationsDelegates,
        routerConfig: widget.routerConfig,
        localeListResolutionCallback: widget.localeListResolutionCallback,
        localeResolutionCallback: widget.localeResolutionCallback,
      ),
    );
  }
}

/// A mixin that maps platform [WidgetsBindingObserver] events to store
/// actions.
///
/// Implement the methods you care about to return actions that will be
/// dispatched to the store. Return `null` to ignore an event.
///
/// ```dart
/// class MyObserver with WidgetBindingReducer<AppAction> {
///   @override
///   AppAction? didChangePlatformBrightness(Brightness brightness) =>
///     AppAction.setBrightness(brightness);
///
///   @override
///   AppAction? didChangeLocales(List<Locale>? locales) =>
///     locales != null ? AppAction.setLocale(locales.first) : null;
/// }
/// ```
mixin WidgetBindingReducer<Action> {
  /// Called when the system locales change.
  Action? didChangeLocales(List<Locale>? locales) => null;

  /// Called when the platform brightness (dark/light mode) changes.
  Action? didChangePlatformBrightness(Brightness brightness) => null;

  /// Called when accessibility features change.
  Action? didChangeAccessibilityFeatures() => null;

  /// Called when the app lifecycle state changes (paused, resumed, etc.).
  Action? didChangeAppLifecycleState(AppLifecycleState state) => null;

  /// Called when the user requests to exit the app.
  Action? didRequestAppExit() => null;

  /// Called when the system is under memory pressure.
  Action? didHaveMemoryPressure() => null;

  /// Called when the text scale factor changes.
  Action? didChangeTextScaleFactor() => null;

  /// Called when screen metrics change (size, orientation, etc.).
  Action? didChangeMetrics() => null;
}
