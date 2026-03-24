part of 'address_book.dart';

class AddressBook extends StatelessWidget {
  final Store<AddressBookState, AddressBookAction> store =
      Store.emptyEnvironment(
        AddressBookState(contacts: []),
        addressBookReducer,
      );
  AddressBook({super.key});

  static const String route = "/address-book";

  // Generate a random contact
  static ContactState generateContact() {
    final id = UniqueKey().toString();
    return ContactState(id: id, name: "Contact $id", email: "Email $id");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(context, "Address Book"),
      body: ForEachStore.id(
        store: store,
        getIterable: contactLens.get,
        embedAction: contactPrism.embed,
        toID: (ContactState e) => e.id,
        iterableBuilder: IterableBuilder.column(context),
        builder: (context, Store<ContactState, ContactAction> store, id) =>
            ContactCard(store: store),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => store.send(AddressBookAction.add(generateContact())),
        tooltip: "Add",
        heroTag: "address-book-add",
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final Store<ContactState, ContactAction> store;

  const ContactCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return WithStore(
      store: store,
      builder: (contact, send, context) => ListTile(
        title: Text(contact.name),
        subtitle: Text(contact.email),
        leading: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => send(const ContactAction.editName("New Name")),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => send(const ContactAction.delete()),
        ),
      ),
    );
  }
}
