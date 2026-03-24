part of 'address_book.dart';

class AddressBookState {
  final List<ContactState> contacts;

  const AddressBookState({required this.contacts});
}

class ContactState {
  final String id;
  final String name;
  final String email;

  const ContactState({
    required this.id,
    required this.name,
    required this.email,
  });

  ContactState copyWith({String? id, String? name, String? email}) {
    return ContactState(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ContactState &&
        other.id == id &&
        other.name == name &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, name, email);

  @override
  String toString() => 'ContactState(id: $id, name: $name, email: $email)';
}

sealed class ContactAction {
  const ContactAction();
  const factory ContactAction.editName(String name) = ContactActionEditName;
  const factory ContactAction.editEmail(String email) = ContactActionEditEmail;
  const factory ContactAction.delete() = ContactActionDelete;
}

class ContactActionEditName extends ContactAction {
  final String name;
  const ContactActionEditName(this.name);
}

class ContactActionEditEmail extends ContactAction {
  final String email;
  const ContactActionEditEmail(this.email);
}

class ContactActionDelete extends ContactAction {
  const ContactActionDelete();
}

final contactReducer =
    Reducer<ContactState, ContactAction, EmptyEnvironment>.transform((
      state,
      action,
      env,
    ) {
      switch (action) {
        case ContactActionEditName(:final name):
          return state.copyWith(name: name);
        case ContactActionEditEmail(:final email):
          return state.copyWith(email: email);
        default:
          return state;
      }
    });

sealed class AddressBookAction {
  const AddressBookAction();
  const factory AddressBookAction.add(ContactState contactState) =
      AddressBookActionAdd;
  const factory AddressBookAction.edit(String id, ContactAction action) =
      AddressBookActionEdit;
}

class AddressBookActionAdd extends AddressBookAction {
  final ContactState contactState;
  const AddressBookActionAdd(this.contactState);
}

class AddressBookActionEdit extends AddressBookAction {
  final String id;
  final ContactAction action;
  const AddressBookActionEdit(this.id, this.action);
}

Lens<AddressBookState, Iterable<ContactState>> contactLens = (
  get: (state) => state.contacts,
  set: (state, contacts) => AddressBookState(contacts: contacts.toList()),
);

Prism<AddressBookAction, ContactAction, String> contactPrism = (
  extract: (action) => switch (action) {
    AddressBookActionEdit(:final id, :final action) => (id, action),
    _ => null,
  },
  embed: (id, localAction) => AddressBookAction.edit(id, localAction),
);

final addressBookReducer =
    Reducer<AddressBookState, AddressBookAction, EmptyEnvironment>.combine([
      contactReducer.forEach(
        stateLens: contactLens,
        actionPrism: contactPrism,
        toID: (e) => e.id,
        toLocalEnvironment: (_, e) => e,
      ),
      Reducer<AddressBookState, AddressBookAction, EmptyEnvironment>.transform((
        state,
        action,
        env,
      ) {
        switch (action) {
          case AddressBookActionAdd(:final contactState):
            return AddressBookState(
              contacts: [...state.contacts, contactState],
            );
          case AddressBookActionEdit(:final id, :final action):
            if (action is ContactActionDelete) {
              return AddressBookState(
                contacts: state.contacts.where((c) => c.id != id).toList(),
              );
            } else {
              return state;
            }
        }
      }),
    ]);
