part of 'simple_text_field.dart';

class SimpleTextFieldState {
  final String text;
  final List<String> events;

  SimpleTextFieldState({this.text = '', this.events = const []});

  SimpleTextFieldState copyWith({String? text, List<String>? events}) {
    return SimpleTextFieldState(
      text: text ?? this.text,
      events: events ?? this.events,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SimpleTextFieldState &&
        other.text == text &&
        other.events.length == events.length;
  }

  @override
  int get hashCode => text.hashCode ^ events.length.hashCode;
}

sealed class SimpleTextFieldAction {
  const SimpleTextFieldAction();

  const factory SimpleTextFieldAction.edit(TextEditingAction action) =
      TextChangedAction;

  const factory SimpleTextFieldAction.none() = SimpleTextFieldNoneAction;
}

class SimpleTextFieldNoneAction extends SimpleTextFieldAction {
  const SimpleTextFieldNoneAction();
}

class TextChangedAction extends SimpleTextFieldAction {
  final TextEditingAction action;
  const TextChangedAction(this.action);
}

final Lens<SimpleTextFieldState, String> textStateLens = (
  get: (state) => state.text,
  set: (state, text) => state.copyWith(text: text),
);

final ActionLens<SimpleTextFieldAction, TextEditingAction> textActionLens = (
  embed: (textAction) => TextChangedAction(textAction),
  extract: (action) => action is TextChangedAction ? action.action : null,
);

final Reducer<SimpleTextFieldState, SimpleTextFieldAction, EmptyEnvironment>
simpleTextFieldReducer = textEditingReducer.pullback(
  stateLens: textStateLens,
  actionLens: textActionLens,
);
