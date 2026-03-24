import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:flutter/widgets.dart';

/// A type-based service locator for dependency injection.
///
/// Register dependencies by type and resolve them later. Optionally
/// configure an [environmentBuilder] and [storeBuilder] to wire up
/// the full application graph.
///
/// ```dart
/// final provider = DependencyProvider()
///   ..register<ApiClient>(ApiClient())
///   ..register<Database>(Database());
///
/// final api = provider.resolve<ApiClient>();
/// ```
class DependencyProvider<AppState, AppAction, AppEnvironment> {
  /// The registered dependency instances, keyed by type.
  final Map<Type, dynamic> dependencies;

  late final AppEnvironment Function(DependencyProvider<AppState, AppAction, AppEnvironment> provider)
      _appEnvironmentBuilder;

  /// The application store, built from [storeBuilder] if provided.
  late final Store<AppState, AppAction> store;

  /// The application environment, built from [environmentBuilder].
  AppEnvironment get environment => _appEnvironmentBuilder(this);

  /// Creates a dependency provider.
  ///
  /// If [environmentBuilder] is provided, it is used to construct the
  /// environment from the provider itself (enabling circular references).
  /// If [storeBuilder] is provided, it creates the store using the
  /// built environment.
  DependencyProvider({
    this.dependencies = const {},
    AppEnvironment Function(DependencyProvider<AppState, AppAction, AppEnvironment> provider)? environmentBuilder,
    Store<AppState, AppAction> Function(AppEnvironment env)? storeBuilder,
  }) {
    if (environmentBuilder != null) {
      _appEnvironmentBuilder = environmentBuilder;
    }
    if (storeBuilder != null) {
      store = storeBuilder(environment);
    }
  }

  /// Resolves a dependency by type [T].
  ///
  /// Throws an assertion error if no dependency of type [T] is registered.
  T resolve<T>() {
    assert(dependencies.containsKey(T), 'Dependency not found for $T');
    return dependencies[T] as T;
  }

  /// Resolves a dependency by type [T], returning `null` if not found.
  T? resolveOrNull<T>() {
    if (!dependencies.containsKey(T)) {
      return null;
    }
    return dependencies[T] as T;
  }

  /// Registers a [dependency] instance under type [T].
  void register<T>(T dependency) {
    dependencies[T] = dependency;
  }
}

/// An [InheritedWidget] that provides a [DependencyProvider] to the widget
/// tree.
///
/// Wrap your app (or a subtree) with [Dependency] to make dependencies
/// available via [Dependency.of].
///
/// ```dart
/// Dependency(
///   dependencyProvider: provider,
///   child: MyApp(),
/// );
///
/// // Later, in any descendant widget:
/// final api = Dependency.of<AppState, AppAction, AppEnv>(context)
///   .resolve<ApiClient>();
/// ```
class Dependency extends InheritedWidget {
  /// The dependency provider accessible to descendant widgets.
  final DependencyProvider dependencyProvider;

  /// Creates a [Dependency] inherited widget.
  const Dependency({
    super.key,
    required this.dependencyProvider,
    required super.child,
  });

  /// Retrieves the [DependencyProvider] from the nearest [Dependency]
  /// ancestor.
  ///
  /// Throws if no [Dependency] widget is found in the tree.
  static DependencyProvider<AppState, AppAction, AppEnvironment> of<AppState, AppAction, AppEnvironment>(
    BuildContext context,
  ) {
    final Dependency? dependency = context.dependOnInheritedWidgetOfExactType<Dependency>();
    if (dependency == null) {
      throw Exception('Dependency not found');
    }
    return dependency.dependencyProvider as DependencyProvider<AppState, AppAction, AppEnvironment>;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
