// ignore_for_file: must_be_immutable

import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'models/counter_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'models/person_store.dart';
import 'utils/testable_with_store.dart';

class CounterWidget extends WidgetBuilderTest {
  @override
  final Store<CounterState, CounterAction> store;

  CounterWidget({required WidgetTester tester, required this.store}) : super(tester: tester);
}

class PersonWidget extends WidgetBuilderTest {
  @override
  final Store<PersonState, PersonAction> store;

  PersonWidget({required super.tester, required this.store, super.observe});
}

void main() {
  testWidgets("Test rebuild", (WidgetTester tester) async {
    final widget = CounterWidget(
      tester: tester,
      store: Store.emptyEnvironment(
        CounterState(0),
        counterReducer,
      ),
    );

    final expectationList = <ActionExpectation<CounterState, CounterAction>>[
      (
        action: CounterAction.increment,
        expectedState: CounterState(1),
        expectedBuild: true,
      ),
      (
        action: CounterAction.increment,
        expectedState: CounterState(2),
        expectedBuild: true,
      ),
      (
        action: CounterAction.reset,
        expectedState: CounterState(0),
        expectedBuild: true,
      ),
      (
        action: CounterAction.reset,
        expectedState: CounterState(0),
        expectedBuild: false,
      ),
    ];

    await widget.pumpWidgetAndExpectRebuild(expectationList);
  });

  testWidgets("Test rebuild on person", (widgetTester) async {
    final widget = PersonWidget(
      tester: widgetTester,
      store: Store.emptyEnvironment(
        PersonState(age: 0, name: ""),
        personReducer,
      ),
    );

    final expectationList = <ActionExpectation<PersonState, PersonAction>>[
      (
        action: PersonAction.setName("Alice"),
        expectedState: PersonState(age: 0, name: "Alice"),
        expectedBuild: true,
      ),
      (
        action: PersonAction.setAge(25),
        expectedState: PersonState(age: 25, name: "Alice"),
        expectedBuild: true,
      ),
      (
        action: PersonAction.setName("Alice"),
        expectedState: PersonState(age: 25, name: "Alice"),
        expectedBuild: false,
      ),
    ];
    await widget.pumpWidgetAndExpectRebuild(expectationList);
  });

  testWidgets("Test rebuild on observed age", (WidgetTester tester) async {
    final widget = PersonWidget(
      tester: tester,
      store: Store.emptyEnvironment(
        PersonState(age: 0, name: ""),
        personReducer,
      ),
      observe: (state) => state.age,
    );

    final expectationList = <ActionExpectation<PersonState, PersonAction>>[
      (
        action: PersonAction.setName("Bob"),
        expectedState: PersonState(age: 0, name: "Bob"),
        expectedBuild: false,
      ),
      (
        action: PersonAction.setAge(30),
        expectedState: PersonState(age: 30, name: "Bob"),
        expectedBuild: true,
      ),
      (
        action: PersonAction.setName("Alice"),
        expectedState: PersonState(age: 30, name: "Alice"),
        expectedBuild: false,
      ),
      (
        action: PersonAction.setAge(30),
        expectedState: PersonState(age: 30, name: "Alice"),
        expectedBuild: false,
      ),
    ];
    await widget.pumpWidgetAndExpectRebuild(expectationList);
  });
}
