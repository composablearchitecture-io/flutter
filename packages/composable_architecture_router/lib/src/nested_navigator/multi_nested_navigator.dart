part of 'index.dart';

class MultiNestedNavigator<AppState, AppAction> extends NestedNavigator<AppState, AppAction> {
  final List<List<ComposableRouterPage<AppState, AppAction, dynamic, dynamic>>> stacks;

  const MultiNestedNavigator(super.builder, this.stacks);

  List<Widget> buildAll(BuildContext context, List<GlobalKey<NavigatorState>> keys) {
    return stacks.enumerated().map((e) => builder!.build(context, keys[e.key], e.value)).toList(growable: false);
  }

  Widget buildAt(int index, BuildContext context, GlobalKey<NavigatorState> key) {
    return builder!.build(context, key, stacks[index]);
  }
}
