part of 'index.dart';

class SingleNestedNavigator<AppState, AppAction> extends NestedNavigator<AppState, AppAction> {
  final List<ComposableRouterPage<AppState, AppAction, dynamic, dynamic>> pages;

  const SingleNestedNavigator(super.builder, this.pages);

  Widget build(BuildContext context, GlobalKey<NavigatorState> key) {
    return builder!.build(context, key, pages);
  }
}
