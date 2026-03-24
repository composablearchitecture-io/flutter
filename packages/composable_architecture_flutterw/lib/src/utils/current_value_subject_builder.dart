import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:flutter/widgets.dart';

/// A stateful widget that subscribes to a [Store]'s state observable and
/// rebuilds when the state changes (according to [isEqual]).
///
/// This is the low-level building block used internally by [WithStore].
/// Most users should use [WithStore] instead.
class CurrentValueSubjectBuilder<S, A> extends StatefulWidget {
  final Store<S, A> store;
  final Widget Function(BuildContext context, S state, Widget? child) builder;
  final bool Function(S previous, S current) isEqual;
  final Widget? child;

  const CurrentValueSubjectBuilder({
    super.key,
    required this.store,
    required this.builder,
    required this.isEqual,
    this.child,
  });

  @override
  State<CurrentValueSubjectBuilder<S, A>> createState() => _CurrentValueSubjectBuilderState<S, A>();
}

class _CurrentValueSubjectBuilderState<S, A> extends State<CurrentValueSubjectBuilder<S, A>> {
  late final int subscriptionId;
  late S value;

  @override
  void initState() {
    super.initState();
    value = widget.store.state;
    subscriptionId = widget.store.stateObservable.listen(
      (state) {
        if (mounted && !widget.isEqual(value, state)) {
          setState(() => value = state);
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    widget.store.stateObservable.cancel(subscriptionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }
}
