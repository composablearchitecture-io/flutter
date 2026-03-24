import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:flutter/material.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';

/// A widget that renders different content based on the runtime type of the
/// store's state.
///
/// Useful when your state is a sealed class hierarchy and each variant
/// should render a different widget.
///
/// ## Example
///
/// ```dart
/// SwitchStore<AuthState, AuthAction>(
///   store: authStore,
///   typeMap: {
///     LoggedIn: (context, store) => HomeScreen(store: store),
///     LoggedOut: (context, store) => LoginScreen(store: store),
///   },
/// );
/// ```
///
/// ## Fluent API
///
/// ```dart
/// SwitchStore(store: store)
///   .when<LoggedIn>((ctx, store) => HomeScreen(store: store))
///   .when<LoggedOut>((ctx, store) => LoginScreen(store: store));
/// ```
class SwitchStore<S, A> extends StatelessWidget {
  /// The store whose state type determines which builder is used.
  final Store<S, A> store;

  /// Map from [Type] to builder function.
  final Map<Type, dynamic> typeMap;

  /// Fallback widget when no type matches.
  final Widget Function(BuildContext context)? orElse;

  /// Creates a [SwitchStore] with a type-to-builder mapping.
  const SwitchStore({
    Key? key,
    required this.store,
    this.typeMap = const {},
    this.orElse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WithStore.observe(
      store: store,
      observe: (observedState) => observedState.runtimeType,
      builder: (type, send, context) =>
          typeMap.containsKey(type) ? typeMap[type]!(context, store) : orElse?.call(context) ?? const SizedBox.shrink(),
    );
  }

  /// Adds a type mapping using a fluent API.
  ///
  /// Returns a new [SwitchStore] with the [T] -> [builder] mapping added.
  /// The builder receives a `Store<T, A>` scoped to the matched state type.
  SwitchStore<S, A> when<T>(
    Widget Function(BuildContext context, Store<T, A> store) builder,
  ) {
    return SwitchStore(
      store: store,
      typeMap: Map.fromEntries([
        MapEntry(
          T,
          (context, Store<S, A> store) => builder(
            context,
            store.scopeState(toLocalState: (p0) => p0 as T),
          ),
        ),
        ...typeMap.entries,
      ]),
      orElse: orElse,
    );
  }
}
