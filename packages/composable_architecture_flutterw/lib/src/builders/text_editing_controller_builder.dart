import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:flutter/widgets.dart';

/// Actions emitted by a [TextEditingControllerBuilder] in response to
/// text input events.
///
/// Map these to your feature's action type via the [fromTextEditingAction]
/// parameter.
sealed class TextEditingAction {
  const TextEditingAction();

  /// The text content has changed.
  const factory TextEditingAction.edit(String text) = TextEditingActionEdit;

  /// A key event occurred while the text field was focused.
  const factory TextEditingAction.onKeyEvent(FocusNode node, KeyEvent event) = TextEditingActionOnKeyEvent;

  /// The focus state of the text field changed.
  const factory TextEditingAction.onFocusChange(FocusNode node) = TextEditingActionOnFocusChange;
}

/// Text content changed. See [TextEditingAction.edit].
class TextEditingActionEdit extends TextEditingAction {
  /// The new text value.
  final String text;

  /// Creates a text edit action.
  const TextEditingActionEdit(this.text);
}

/// Key event occurred. See [TextEditingAction.onKeyEvent].
class TextEditingActionOnKeyEvent extends TextEditingAction {
  /// The focus node that received the key event.
  final FocusNode node;

  /// The key event.
  final KeyEvent event;

  /// Creates a key event action.
  const TextEditingActionOnKeyEvent(this.node, this.event);
}

/// Focus changed. See [TextEditingAction.onFocusChange].
class TextEditingActionOnFocusChange extends TextEditingAction {
  /// The focus node whose focus state changed.
  final FocusNode node;

  /// Creates a focus change action.
  const TextEditingActionOnFocusChange(this.node);
}

/// A stateful widget that manages a [TextEditingController] and [FocusNode]
/// with two-way binding to a [Store].
///
/// The controller's text is synchronized with the store's state via [toText].
/// User input dispatches actions via [fromTextEditingAction]. State changes
/// from other sources update the controller text automatically.
///
/// Typically used via [WithStore.textEditingController] rather than directly.
///
/// ```dart
/// TextEditingControllerBuilder<MyState, MyAction>(
///   store: store,
///   toText: (state) => state.searchQuery,
///   fromTextEditingAction: (a) => MyAction.textEditing(a),
///   builder: (controller, focusNode) => TextField(
///     controller: controller,
///     focusNode: focusNode,
///   ),
/// );
/// ```
class TextEditingControllerBuilder<S, A> extends StatefulWidget {
  /// Builder that receives the managed controller and focus node.
  final Widget Function(TextEditingController, FocusNode) builder;

  /// Extracts the text value from the store's state.
  final String Function(S state) toText;

  /// Maps [TextEditingAction]s to the store's action type.
  final A Function(TextEditingAction action) fromTextEditingAction;

  /// The store to synchronize with.
  final Store<S, A> store;

  /// Creates a [TextEditingControllerBuilder].
  const TextEditingControllerBuilder({
    super.key,
    required this.builder,
    required this.toText,
    required this.fromTextEditingAction,
    required this.store,
  });

  @override
  State<TextEditingControllerBuilder<S, A>> createState() => _TextEditingControllerBuilderState<S, A>();
}

/// A pre-built reducer for simple text state managed by a
/// [TextEditingControllerBuilder].
///
/// Updates the `String` state when a [TextEditingActionEdit] is received
/// with a different text value.
final textEditingReducer = Reducer<String, TextEditingAction, EmptyEnvironment>.transform(
  (state, action, env) => switch (action) {
    TextEditingActionEdit(:final text) when text != state => text,
    _ => state,
  },
);

class _TextEditingControllerBuilderState<S, A> extends State<TextEditingControllerBuilder<S, A>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final int subscriptionId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _controller.text = widget.toText(widget.store.state);

    _controller.addListener(
      () {
        widget.store.send(
          widget.fromTextEditingAction(
            TextEditingAction.edit(_controller.text),
          ),
        );
      },
    );
    subscriptionId = widget.store.stateObservable.listen(
      (value) {
        if (_controller.text != widget.toText(value)) {
          _controller.text = widget.toText(value);
        }
      },
    );
    _focusNode.onKeyEvent = (node, event) {
      widget.store.send(
        widget.fromTextEditingAction(
          TextEditingAction.onKeyEvent(node, event),
        ),
      );
      return KeyEventResult.ignored;
    };

    _focusNode.addListener(
      () => widget.store.send(
        widget.fromTextEditingAction(
          TextEditingAction.onFocusChange(_focusNode),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.store.stateObservable.cancel(subscriptionId);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_controller, _focusNode);
  }
}
