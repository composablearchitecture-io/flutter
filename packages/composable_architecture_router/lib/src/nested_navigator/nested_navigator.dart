part of 'index.dart';

sealed class NestedNavigator<AppState, AppAction> {
  final RouterBuilder? builder;

  const NestedNavigator(this.builder);

  const factory NestedNavigator.none() = NoNestedNavigator<AppState, AppAction>;

  const factory NestedNavigator.single(
    RouterBuilder builder,
    List<ComposableRouterPage<AppState, AppAction, dynamic, dynamic>> pages,
  ) = SingleNestedNavigator<AppState, AppAction>;

  const factory NestedNavigator.multi(
    RouterBuilder builder,
    List<List<ComposableRouterPage<AppState, AppAction, dynamic, dynamic>>> stacks,
  ) = MultiNestedNavigator<AppState, AppAction>;

  const factory NestedNavigator.tabs(
    RouterBuilder builder,
    List<List<ComposableRouterPage<AppState, AppAction, dynamic, dynamic>>> stacks,
    int currentTab,
  ) = TabNestedNavigator<AppState, AppAction>;
}
