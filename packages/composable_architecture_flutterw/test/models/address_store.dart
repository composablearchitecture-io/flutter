import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:flutter/foundation.dart';

import 'person_store.dart';

class AddressBookState {
  final List<PersonState> addresses;

  AddressBookState({required this.addresses});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressBookState && listEquals(addresses, other.addresses);
  }

  @override
  int get hashCode => addresses.map((e) => e.hashCode).fold(0, (prev, element) => prev ^ element);
}

sealed class AddressBookAction {
  const AddressBookAction();

  const factory AddressBookAction.addPerson(PersonState person) = AddressBookActionAddPerson;
  const factory AddressBookAction.removePerson(String id) = AddressBookActionRemovePerson;
  const factory AddressBookAction.updatePerson(String id, PersonAction action) = AddressBookActionUpdatePerson;
}

class AddressBookActionAddPerson implements AddressBookAction {
  final PersonState person;
  const AddressBookActionAddPerson(this.person);
}

class AddressBookActionRemovePerson implements AddressBookAction {
  final String id;
  const AddressBookActionRemovePerson(this.id);
}

class AddressBookActionUpdatePerson implements AddressBookAction {
  final String id;
  final PersonAction action;
  const AddressBookActionUpdatePerson(this.id, this.action);
}

Prism<AddressBookAction, PersonAction, String> addressBookActionPrism = (
  embed: (id, action) => AddressBookAction.updatePerson(id, action),
  extract: (action) => action is AddressBookActionUpdatePerson ? (action.id, action.action) : null,
);

Lens<AddressBookState, Iterable<PersonState>> addressBookStateLens = (
  get: (state) => state.addresses,
  set: (state, localStates) => AddressBookState(addresses: localStates.toList(growable: false)),
);

final Reducer<AddressBookState, AddressBookAction, EmptyEnvironment> addressBookReducer = Reducer.combine([
  Reducer.transform(
    (state, action, env) => switch (action) {
      AddressBookActionAddPerson(:final person) => AddressBookState(
          addresses: [...state.addresses, person],
        ),
      AddressBookActionRemovePerson(:final id) => AddressBookState(
          addresses: [...state.addresses.where((e) => e.name != id)],
        ),
      _ => state,
    },
  ),
  personReducer.forEach(
    stateLens: addressBookStateLens,
    actionPrism: addressBookActionPrism,
    toID: (state) => state.name,
  ),
]);
