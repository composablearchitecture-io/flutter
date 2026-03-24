import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:flutter/material.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_flutterw/src/utils/for_each_utils.dart';
import 'package:flutter_test/flutter_test.dart';

typedef ActionExpectation<S, A> = ({S expectedState, bool expectedBuild, A action});

// ignore: must_be_immutable
abstract class WidgetBuilderTest<S, A, ObservedState> extends StatelessWidget {
  Store<S, A> get store;

  final WidgetTester tester;
  final ObservedState Function(S state)? observe;

  var _buildCount = 0;
  int get buildCounts => _buildCount;

  WidgetBuilderTest({
    super.key,
    required this.tester,
    this.observe,
  });

  @override
  Widget build(BuildContext context) {
    builder(state, send, BuildContext context) {
      _buildCount++;
      return Container();
    }

    if (observe == null) {
      return WithStore(
        store: store,
        builder: builder,
      );
    } else {
      return WithStore.observe(
        store: store,
        builder: builder,
        observe: observe!,
      );
    }
  }

  Future<void> send(A action) async {
    store.send(action);
    await tester.pump();
  }

  Future<void> pumpWidget() async {
    await tester.pumpWidget(this);
  }

  Future<void> pumpWidgetAndExpectRebuild(List<ActionExpectation<S, A>> expectations) async {
    var expectedBuildCounts = buildCounts;
    await pumpWidget();
    expectedBuildCounts += 1; // initial build
    expect(buildCounts, expectedBuildCounts);
    for (final expectation in expectations) {
      await send(expectation.action);
      expect(store.state, expectation.expectedState);
      if (expectation.expectedBuild) {
        expectedBuildCounts += 1;
      }
      expect(buildCounts, expectedBuildCounts);
    }
  }
}

typedef ActionForEachExpectation<GlobalState, GlobalAction, ID> = ({
  GlobalAction action,
  GlobalState expectedState,
  Map<ID, bool> expectedBuilds,
});

// ignore: must_be_immutable
class ForEachTestable<ID, GlobalState, GlobalAction, ItemState, ItemAction> extends StatelessWidget {
  final Store<GlobalState, GlobalAction> store;
  final ID Function(ItemState state) toID;
  final Iterable<ItemState> Function(GlobalState) getIterable;
  final GlobalAction Function(ID, ItemAction) embedAction;
  Map<ID, int> buildCounts = {};
  final WidgetTester tester;

  ForEachTestable({
    Key? key,
    required this.store,
    required this.toID,
    required this.getIterable,
    required this.embedAction,
    required this.tester,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: ForEachStore.id(
          builder: (context, store, id) => WithStore(
            store: store,
            builder: (state, send, context) {
              buildCounts[id] = (buildCounts[id] ?? 0) + 1;
              return Container();
            },
          ),
          store: store,
          getIterable: getIterable,
          embedAction: embedAction,
          toID: toID,
          iterableBuilder: IterableBuilder.column(context),
        ),
      );

  Future<void> pumpWidget() async {
    await tester.pumpWidget(this);
  }

  Future<void> send(GlobalAction action) async {
    store.send(action);
    await tester.pump();
  }

  Future<void> pumpWidgetExpectations(
    List<ActionForEachExpectation<GlobalState, GlobalAction, ID>> expectations,
  ) async {
    Map<ID, int> expectedBuildCounts = {};
    await pumpWidget();
    for (final expectation in expectations) {
      await send(expectation.action);
      expect(store.state, expectation.expectedState);
      for (final id in buildCounts.keys) {
        if (expectation.expectedBuilds[id] == true) {
          expectedBuildCounts[id] = expectedBuildCounts[id] == null ? buildCounts[id]! : expectedBuildCounts[id]! + 1;
        }
      }
      for (final id in expectation.expectedBuilds.keys) {
        expect(buildCounts[id], expectedBuildCounts[id]);
      }
    }
  }
}
