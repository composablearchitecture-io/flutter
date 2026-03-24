import 'package:composable_architecture_core/composable_architecture_core.dart';

class CounterState {
  final int count;
  const CounterState(this.count);

  CounterState copyWith({int? count}) {
    return CounterState(count ?? this.count);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CounterState && other.count == count;
  }

  @override
  int get hashCode => count.hashCode;
}

enum CounterAction { increment, decrement, reset }

final counterReducer = Reducer.transform(
  (CounterState state, CounterAction action, EmptyEnvironment env) => switch (action) {
    CounterAction.increment => state.copyWith(count: state.count + 1),
    CounterAction.decrement => state.copyWith(count: state.count - 1),
    CounterAction.reset => state.copyWith(count: 0),
  },
);
