part of 'counter.dart';

class CounterPage extends StatelessWidget {
  final Store<int, CounterAction> store = Store.emptyEnvironment(
    0,
    counterReducer,
  );
  CounterPage({super.key});

  static const String route = "/counter";

  @override
  Widget build(BuildContext context) {
    return WithStore<int, CounterAction>(
      store: store,
      builder: (state, send, context) {
        return Scaffold(
          appBar: getAppBar(context, "Counter"),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "$state",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: () => send(CounterAction.decrement),
                      tooltip: "Decrement",
                      heroTag: "counter-decrement",
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                      onPressed: () => send(CounterAction.increment),
                      tooltip: "Increment",
                      heroTag: "counter-increment",
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => send(CounterAction.reset),
            tooltip: "Reset",
            heroTag: "counter-reset",
            child: const Icon(Icons.refresh),
          ),
        );
      },
    );
  }
}
