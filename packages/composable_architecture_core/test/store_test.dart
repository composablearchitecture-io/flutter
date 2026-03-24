import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:test/test.dart';

import 'utils/models.dart';

void main() {
  test("counter test", () {
    final store = TestStore(
      Person(age: 10, firstName: "John", lastName: "Doe"),
      getPersonReducer(),
      null,
    );

    ageExpectation(int age) => (Person state) => expect(state.age, age);
    store.checkState(ageExpectation(10));
    store.send(PersonAction.incrementAge(12), expected: ageExpectation(12));
  });

  test("group pullback test", () {
    var counterPersonReducerCalls = 0;
    var counterGroupReducerCalls = 0;
    final store = Store.emptyEnvironment(
      Group(
        person: Person(age: 10, firstName: "John", lastName: "Doe"),
      ),
      getGroupReducer(
        personReducer: getPersonReducer(callback: (_, __, ___) => counterPersonReducerCalls++),
        callback: (_, __, ___) => counterGroupReducerCalls++,
      ),
    );

    expect(store.state.person.age, 10);
    store.send(
      GroupAction.personAction(PersonAction.incrementAge(12)),
    );
    expect(store.state.person.age, 12);

    final personStore = store.scope<Person, PersonAction>(
      toLocalState: (group) => group.person,
      toGlobalAction: (personAction) => GroupAction.personAction(personAction),
    );

    expect(personStore.state.age, 12);
    personStore.send(PersonAction.incrementAge(15));
    expect(personStore.state.age, 15);

    store.send(GroupAction.sayHello());

    expect(counterPersonReducerCalls, 2);
    expect(counterGroupReducerCalls, 3);
  });
}
