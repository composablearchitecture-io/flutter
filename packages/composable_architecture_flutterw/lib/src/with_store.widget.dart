import 'package:flutter/widgets.dart';
import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_flutterw/src/utils/current_value_subject_builder.dart';

/// The primary widget for connecting a [Store] to the Flutter widget tree.
///
/// Rebuilds its [builder] whenever the store's state changes (according to
/// [isEqual]). The builder receives the current state, a `send` function
/// for dispatching actions, and the build context.
///
/// ## Basic Usage
///
/// ```dart
/// WithStore<int, CounterAction>(
///   store: store,
///   builder: (state, send, context) => Column(
///     children: [
///       Text('$state'),
///       ElevatedButton(
///         onPressed: () => send(CounterAction.increment),
///         child: Text('Increment'),
///       ),
///     ],
///   ),
/// );
/// ```
///
/// ## Scoped Rebuilds
///
/// Use [WithStore.observe] to project state and only rebuild when the
/// projected value changes:
///
/// ```dart
/// WithStore.observe(
///   store: appStore,
///   observe: (state) => state.counter,
///   builder: (count, send, context) => Text('$count'),
/// );
/// ```
///
/// See also:
/// - [ForEachStore] for rendering collections
/// - [IfLetStore] for optional state
/// - [SwitchStore] for type-based state rendering
class WithStore<S, A> extends StatelessWidget {
  /// The store whose state drives this widget's rebuilds.
  final Store<S, A> store;

  /// Builder function called on every state change.
  ///
  /// Receives the current [state], a [send] function for dispatching
  /// actions, and the [BuildContext].
  final Widget Function(S state, void Function(A) send, BuildContext context) builder;

  /// Equality function to determine whether a state change should trigger
  /// a rebuild. Defaults to `==`.
  final bool Function(S previous, S current) isEqual;

  /// Creates a [WithStore] that rebuilds on state changes.
  const WithStore({
    super.key,
    required this.store,
    required this.builder,
    this.isEqual = IsEqualUtils.stateAreEquals,
  });

  /// A no-op builder used internally by subclasses.
  static Widget voidBuilder<S, A>(S state, void Function(A) send, BuildContext context) => Container();

  /// Creates a [WithStore] that projects state via [observe] before building.
  ///
  /// The widget only rebuilds when the observed (projected) value changes,
  /// not when unrelated parts of the global state change.
  ///
  /// ```dart
  /// WithStore.observe(
  ///   store: appStore,
  ///   observe: (state) => state.username,
  ///   builder: (username, send, context) => Text(username),
  /// );
  /// ```
  static WithStore<ObservedState, A> observe<S, ObservedState, A>({
    required Store<S, A> store,
    required ObservedState Function(S state) observe,
    required Widget Function(ObservedState state, void Function(A action) send, BuildContext context) builder,
    bool Function(ObservedState previous, ObservedState current) isEqual = IsEqualUtils.stateAreEquals,
    Key? key,
  }) =>
      WithStore(
        key: key,
        store: store.scopeState(toLocalState: observe),
        builder: builder,
        isEqual: isEqual,
      );

  /// Creates a [WithStore] with a two-way bound [TextEditingController].
  ///
  /// The controller's text is synchronized with the store's state via
  /// [toText], and text changes dispatch actions via [fromTextEditingAction].
  ///
  /// ```dart
  /// WithStore.textEditingController(
  ///   store: store,
  ///   toText: (state) => state.query,
  ///   fromTextEditingAction: (a) => SearchAction.fromTextEditing(a),
  ///   builder: (state, send, context, controller, focusNode) =>
  ///     TextField(controller: controller, focusNode: focusNode),
  /// );
  /// ```
  static WithStore<void, A> textEditingController<S, A>({
    required Store<S, A> store,
    required String Function(S state) toText,
    required A Function(TextEditingAction action) fromTextEditingAction,
    required TextEditingControllerWithStoreBuilder<void, A> builder,
    Key? key,
  }) =>
      WithStore.textEditingControllerObserve<void, S, A>(
        store: store,
        observe: (observedState) {},
        isEqual: (previous, current) => true,
        toText: toText,
        fromTextEditingAction: fromTextEditingAction,
        builder: builder,
      );

  /// Combines state observation with a [TextEditingController] binding.
  ///
  /// Projects state via [observe] for selective rebuilds while maintaining
  /// two-way text synchronization.
  static WithStore<ObservedState, A> textEditingControllerObserve<ObservedState, S, A>({
    required Store<S, A> store,
    required ObservedState Function(S observedState) observe,
    required String Function(S state) toText,
    required A Function(TextEditingAction action) fromTextEditingAction,
    required TextEditingControllerWithStoreBuilder<ObservedState, A> builder,
    bool Function(ObservedState previous, ObservedState current) isEqual = IsEqualUtils.stateAreEquals,
    Key? key,
  }) =>
      WithStore<ObservedState, A>(
        store: store.scope(toLocalState: observe, toGlobalAction: (action) => action),
        builder: (state, send, context) => TextEditingControllerBuilder<S, A>(
          key: key,
          builder: (controller, focusNode) => builder(
            state,
            send,
            context,
            controller,
            focusNode,
          ),
          store: store,
          toText: toText,
          fromTextEditingAction: fromTextEditingAction,
        ),
        isEqual: isEqual,
      );

  @override
  Widget build(BuildContext context) {
    return CurrentValueSubjectBuilder<S, A>(
      store: store,
      isEqual: isEqual,
      builder: (context, state, child) => builder(state, store.send, context),
    );
  }
}

/// Builder function for [WithStore.textEditingController] variants.
///
/// Receives the projected state, send function, context, and the managed
/// [TextEditingController] and [FocusNode].
typedef TextEditingControllerWithStoreBuilder<S, A> = Widget Function(
  S state,
  void Function(A action) send,
  BuildContext context,
  TextEditingController controller,
  FocusNode focusNode,
);
