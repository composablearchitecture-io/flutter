import 'package:flutter/material.dart';
import 'package:example/components/appbar.component.dart';
import 'package:example/pages/index.dart';

const Map<String, String> examples = {
  CounterPage.route: "Counter Page",
  AddressBook.route: "Address Book",
  SimpleTextFieldPage.route: "Simple Text Field",
};

class HomePage extends StatelessWidget {
  static String route = "/";

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(context, "Select an example"),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final route = examples.keys.elementAt(index);
          final title = examples[route]!;
          return ListTile(
            title: Text(title),
            onTap: () => Navigator.of(context).pushNamed(route),
          );
        },
        itemCount: examples.length,
      ),
    );
  }
}
