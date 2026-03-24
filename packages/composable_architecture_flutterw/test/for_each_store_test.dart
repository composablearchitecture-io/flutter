import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'models/address_store.dart';
import 'models/person_store.dart';
import 'utils/testable_with_store.dart';

// ignore: must_be_immutable
class AddressBookWidget
    extends ForEachTestable<String, AddressBookState, AddressBookAction, PersonState, PersonAction> {
  AddressBookWidget({super.key, required super.store, required super.tester})
      : super(
          toID: (state) => state.name,
          getIterable: addressBookStateLens.get,
          embedAction: addressBookActionPrism.embed,
        );
}

void main() {
  testWidgets(
    "For each test build",
    (widgetTester) async {
      final widget = AddressBookWidget(
        store: Store.emptyEnvironment(
          AddressBookState(
            addresses: [
              PersonState(age: 20, name: "Bob"),
              PersonState(age: 25, name: "Alice"),
              PersonState(age: 30, name: "Charlie"),
            ],
          ),
          addressBookReducer,
        ),
        tester: widgetTester,
      );
      final expectationList = <ActionForEachExpectation<AddressBookState, AddressBookAction, String>>[
        (
          action: AddressBookAction.addPerson(PersonState(age: 20, name: "John")),
          expectedState: AddressBookState(
            addresses: [
              PersonState(age: 20, name: "Bob"),
              PersonState(age: 25, name: "Alice"),
              PersonState(age: 30, name: "Charlie"),
              PersonState(age: 20, name: "John"),
            ],
          ),
          expectedBuilds: {
            "Bob": true,
            "Alice": true,
            "Charlie": true,
            "John": true,
          }
        ),
        (
          action: AddressBookAction.updatePerson("Bob", PersonAction.setAge(26)),
          expectedState: AddressBookState(
            addresses: [
              PersonState(age: 26, name: "Bob"),
              PersonState(age: 25, name: "Alice"),
              PersonState(age: 30, name: "Charlie"),
              PersonState(age: 20, name: "John"),
            ],
          ),
          expectedBuilds: {
            "Bob": true,
            "Alice": false,
            "Charlie": false,
            "John": false,
          }
        ),
        (
          action: AddressBookAction.updatePerson("Bob", PersonAction.setName("Robert")),
          expectedState: AddressBookState(
            addresses: [
              PersonState(age: 26, name: "Robert"),
              PersonState(age: 25, name: "Alice"),
              PersonState(age: 30, name: "Charlie"),
              PersonState(age: 20, name: "John"),
            ],
          ),
          expectedBuilds: {
            "Robert": true,
            "Alice": false,
            "Charlie": false,
            "John": false,
          }
        ),
        (
          action: AddressBookAction.removePerson("Robert"),
          expectedState: AddressBookState(
            addresses: [
              PersonState(age: 25, name: "Alice"),
              PersonState(age: 30, name: "Charlie"),
              PersonState(age: 20, name: "John"),
            ],
          ),
          expectedBuilds: {
            "Alice": false,
            "Charlie": false,
            "John": false,
          }
        ),
      ];
      await widget.pumpWidgetExpectations(expectationList);
    },
  );
}
