import 'package:example/pages/index.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      routes: {
        HomePage.route: (_) => const HomePage(),
        CounterPage.route: (_) => CounterPage(),
        AddressBook.route: (_) => AddressBook(),
        SimpleTextFieldPage.route: (_) => SimpleTextFieldPage(),
      },
      initialRoute: HomePage.route,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
