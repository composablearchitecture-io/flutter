import 'package:composable_architecture_core/composable_architecture_core.dart';

/// Models and reducers for testing
class Person {
  final String firstName;
  final String lastName;
  final int age;

  Person({
    required this.firstName,
    required this.lastName,
    required this.age,
  });
}

sealed class PersonAction {
  const PersonAction();
  const factory PersonAction.incrementAge(int age) = PersonActionIncrementAge;
  const factory PersonAction.delayedIncrementAge(int age) = PersonActionDelayedIncrementAge;
  const factory PersonAction.isAdult() = PersonActionIsAdult;
}

class PersonActionIncrementAge extends PersonAction {
  final int age;
  const PersonActionIncrementAge(this.age);
}

class PersonActionDelayedIncrementAge extends PersonAction {
  final int age;
  const PersonActionDelayedIncrementAge(this.age);
}

class PersonActionIsAdult extends PersonAction {
  const PersonActionIsAdult();
}

Reducer<Person, PersonAction, EmptyEnvironment> getPersonReducer({
  void Function(Person, PersonAction, EmptyEnvironment)? callback,
  Effect<PersonAction> Function(PersonAction)? effect,
}) {
  return Reducer<Person, PersonAction, EmptyEnvironment>(
    reduce: (p0, p1, p2) {
      callback?.call(p0, p1, p2);
      switch (p1) {
        case PersonActionIncrementAge(:final age):
          return (
            state: Person(
              firstName: p0.firstName,
              lastName: p0.lastName,
              age: age,
            ),
            effect: effect?.call(p1) ?? Effect.none(),
          );
        case PersonActionIsAdult():
          return (state: p0, effect: effect?.call(p1) ?? Effect.none());
        default:
          return (state: p0, effect: Effect.none());
      }
    },
  );
}

/// Group model and actions for testing pullback
class Group {
  final Person person;

  Group({
    required this.person,
  });
}

sealed class GroupAction {
  const GroupAction();
  const factory GroupAction.sayHello() = GroupActionSayHello;
  const factory GroupAction.personAction(PersonAction personAction) = ToPersonAction;
}

class GroupActionSayHello extends GroupAction {
  const GroupActionSayHello();
}

class ToPersonAction extends GroupAction {
  final PersonAction personAction;
  const ToPersonAction(this.personAction);
}

Reducer<Group, GroupAction, EmptyEnvironment> getGroupReducer({
  required Reducer<Person, PersonAction, EmptyEnvironment> personReducer,
  void Function(Group, GroupAction, EmptyEnvironment)? callback,
  Effect<GroupAction> effect = const Effect.none(),
}) {
  return Reducer<Group, GroupAction, EmptyEnvironment>.combine([
    Reducer<Group, GroupAction, EmptyEnvironment>(
      reduce: (state, action, env) {
        callback?.call(state, action, env);
        return (
          state: state,
          effect: effect,
        );
      },
    ),
    personReducer.pullback(
      stateLens: (
        get: (Group group) => group.person,
        set: (Group group, Person person) => Group(person: person),
      ),
      actionLens: (
        embed: GroupAction.personAction,
        extract: (GroupAction action) => action is ToPersonAction ? action.personAction : null,
      ),
      toLocalEnvironment: (env) => env,
    ),
  ]);
}
