part of 'simple_text_field.dart';

class SimpleTextFieldPage extends StatefulWidget {
  final Store<SimpleTextFieldState, SimpleTextFieldAction> store =
      Store.emptyEnvironment(SimpleTextFieldState(), simpleTextFieldReducer);

  SimpleTextFieldPage({super.key});

  static const String route = "/simple-text-field";

  @override
  State<SimpleTextFieldPage> createState() => _SimpleTextFieldPageState();
}

class _SimpleTextFieldPageState extends State<SimpleTextFieldPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(context, "Simple Text Field"),
      body: Center(
        child: Padding(
          padding: .all(20),
          child:
              WithStore.textEditingController<
                SimpleTextFieldState,
                SimpleTextFieldAction
              >(
                store: widget.store,
                toText: (state) => state.text,
                fromTextEditingAction: SimpleTextFieldAction.edit,
                builder: (state, send, context, controller, focusNode) =>
                    TextField(controller: controller, focusNode: focusNode),
              ),
        ),
      ),
    );
  }
}
