part of 'counter.dart';

enum CounterAction { increment, decrement, reset }

final Reducer<int, CounterAction, EmptyEnvironment> counterReducer =
    Reducer.transform(
      (state, action, env) => switch (action) {
        CounterAction.increment => state + 1,
        CounterAction.decrement => state - 1,
        CounterAction.reset => 0,
      },
    );
