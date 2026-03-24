import 'package:composable_architecture_core/composable_architecture_core.dart';

class PersonState {
  final int age;
  final String name;

  const PersonState({
    required this.age,
    required this.name,
  });
  PersonState copyWith({
    int? age,
    String? name,
  }) {
    return PersonState(
      age: age ?? this.age,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonState && other.age == age && other.name == name;
  }

  @override
  int get hashCode => Object.hash(age, name);

  @override
  String toString() {
    return '(age: $age, name: $name)';
  }
}

sealed class PersonAction {
  const PersonAction();

  const factory PersonAction.setAge(int age) = PersonActionSetAge;
  const factory PersonAction.setName(String name) = PersonActionSetName;
}

class PersonActionSetAge implements PersonAction {
  final int age;
  const PersonActionSetAge(this.age);
}

class PersonActionSetName implements PersonAction {
  final String name;
  const PersonActionSetName(this.name);
}

class PersonActionDelete implements PersonAction {
  const PersonActionDelete();
}

final personReducer = Reducer.transform(
  (PersonState state, PersonAction action, EmptyEnvironment env) => switch (action) {
    PersonActionSetAge(:final age) => state.copyWith(age: age),
    PersonActionSetName(:final name) => state.copyWith(name: name),
    PersonActionDelete() => state,
  },
);
