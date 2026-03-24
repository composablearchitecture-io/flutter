import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:flutter/widgets.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';

/// A widget that conditionally renders content based on nullable state.
///
/// When the store's state is non-null, [builder] is called with a
/// non-nullable `Store<S, A>`. When the state is null, [orElse] is
/// rendered (or [SizedBox.shrink] if not provided).
///
/// Only rebuilds when the null/non-null status changes, not on every
/// state change within the non-null branch.
///
/// ## Example
///
/// ```dart
/// IfLetStore<UserProfile, ProfileAction>(
///   store: profileStore, // Store<UserProfile?, ProfileAction>
///   builder: (context, store) => WithStore(
///     store: store,
///     builder: (profile, send, ctx) => Text(profile.name),
///   ),
///   orElse: (context) => Text('No profile'),
/// );
/// ```
///
/// ## With State Projection
///
/// ```dart
/// IfLetStore.observe(
///   store: appStore,
///   toNullableState: (state) => state.selectedUser,
///   toGlobalAction: (action) => AppAction.user(action),
///   builder: (context, store) => UserDetailView(store: store),
/// );
/// ```
class IfLetStore<S, A> extends WithStore<S?, A> {
  final Widget Function(BuildContext context, Store<S, A> store) _builder;

  /// Widget to render when the state is null.
  final Widget Function(BuildContext context)? orElse;

  /// Creates an [IfLetStore] with a nullable state store.
  const IfLetStore({
    super.key,
    required super.store,
    required Widget Function(BuildContext context, Store<S, A> store) builder,
    this.orElse,
  })  : _builder = builder,
        super(builder: WithStore.voidBuilder);

  /// Creates the internal builder that handles null/non-null branching.
  static createBuilder<S, A>(
    Widget Function(BuildContext context, Store<S, A> store) builder,
    final Widget Function(BuildContext context)? orElse,
    Store<S?, A> store,
  ) {
    return (state, send, context) {
      if (state == null) {
        return orElse?.call(context) ?? const SizedBox.shrink();
      } else {
        return builder(
          context,
          store.scopeState(toLocalState: (s) => s ?? state),
        );
      }
    };
  }

  /// Creates an [IfLetStore] by projecting nullable state from a global store.
  ///
  /// Uses [toNullableState] to extract the optional child state and
  /// [toGlobalAction] to embed child actions into the global action type.
  static IfLetStore<NullableState, A> observe<GlobalState, NullableState, GlobalAction, A>({
    Key? key,
    required Store<GlobalState, GlobalAction> store,
    required Widget Function(BuildContext context, Store<NullableState, A> store) builder,
    required NullableState? Function(GlobalState state) toNullableState,
    required GlobalAction Function(A action) toGlobalAction,
    Widget Function(BuildContext context)? orElse,
  }) =>
      IfLetStore(
        store: store.scope(
          toLocalState: toNullableState,
          toGlobalAction: toGlobalAction,
        ),
        builder: builder,
        orElse: orElse,
      );

  @override
  Widget build(BuildContext context) => WithStore(
        store: store,
        isEqual: (previous, current) => previous == null && current == null || current != null && previous != null,
        builder: createBuilder(_builder, orElse, store),
      );
}
