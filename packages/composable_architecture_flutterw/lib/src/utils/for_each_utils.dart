import 'package:flutter/widgets.dart';

/// Factory functions that create layout widgets for [ForEachStore].
///
/// Each factory returns a function matching the `iterableBuilder` signature
/// expected by [ForEachStore]. Pass the returned function directly:
///
/// ```dart
/// ForEachStore.id(
///   iterableBuilder: IterableBuilder.listViewBuilder(),
///   // ...
/// );
/// ```
class IterableBuilder {
  const IterableBuilder._();

  /// Creates a [ListView.builder] (or [ListView.separated] if
  /// [separatorBuilder] is provided).
  static Widget Function({
    required Widget? Function(BuildContext, int) itemBuilder,
    int? itemCount,
  }) listViewBuilder({
    ScrollPhysics? physics,
    Widget Function(BuildContext context, int index)? separatorBuilder,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    bool reverse = false,
  }) =>
      ({required Widget? Function(BuildContext, int) itemBuilder, int? itemCount}) => separatorBuilder == null
          ? ListView.builder(
              itemBuilder: itemBuilder,
              itemCount: itemCount,
              shrinkWrap: shrinkWrap,
              physics: physics,
              padding: padding,
              reverse: reverse,
            )
          : ListView.separated(
              separatorBuilder: separatorBuilder,
              itemBuilder: itemBuilder,
              itemCount: itemCount ?? 0,
              shrinkWrap: shrinkWrap,
              physics: physics,
              padding: padding,
              reverse: reverse,
            );

  /// Creates a [PageView] layout.
  static Widget Function({
    required Widget? Function(BuildContext, int) itemBuilder,
    int? itemCount,
  }) pageController(
    BuildContext context, {
    ScrollPhysics? physics,
    bool allowImplicitScrolling = false,
    PageController? controller,
    Axis scrollDirection = Axis.horizontal,
  }) =>
      ({required Widget? Function(BuildContext, int) itemBuilder, int? itemCount}) => PageView(
            children: List.generate(itemCount ?? 0, (index) => itemBuilder(context, index) ?? Container()),
            physics: physics,
            allowImplicitScrolling: allowImplicitScrolling,
            controller: controller,
            scrollDirection: scrollDirection,
          );

  /// Creates a [SliverReorderableList] for drag-to-reorder within slivers.
  static Widget Function({
    required Widget? Function(BuildContext, int) itemBuilder,
    int? itemCount,
  }) sliverReorderableList({
    required void Function(int oldIndex, int newIndex) onReorder,
    double? autoScrollerVelocityScalar,
    int? Function(Key)? findChildIndexCallback,
    void Function(int)? onReorderEnd,
    void Function(int)? onReorderStart,
    Widget? prototypeItem,
    Widget Function(Widget, int, Animation<double>)? proxyDecorator,
  }) =>
      ({required Widget? Function(BuildContext, int) itemBuilder, int? itemCount}) => SliverReorderableList(
            itemBuilder: (context, index) => itemBuilder(context, index) ?? Container(),
            itemCount: itemCount ?? 0,
            onReorder: onReorder,
            autoScrollerVelocityScalar: autoScrollerVelocityScalar,
            findChildIndexCallback: findChildIndexCallback,
            onReorderEnd: onReorderEnd,
            onReorderStart: onReorderStart,
            prototypeItem: prototypeItem,
            proxyDecorator: proxyDecorator,
          );

  /// Creates a [SliverList.builder] (or [SliverList.separated] if
  /// [separatorBuilder] is provided).
  static Widget Function({
    required Widget? Function(BuildContext, int) itemBuilder,
    int? itemCount,
  }) sliverListBuilder({
    Widget Function(BuildContext context, int index)? separatorBuilder,
  }) =>
      ({required Widget? Function(BuildContext, int) itemBuilder, int? itemCount}) => separatorBuilder == null
          ? SliverList.builder(
              itemBuilder: itemBuilder,
              itemCount: itemCount,
            )
          : SliverList.separated(
              separatorBuilder: separatorBuilder,
              itemBuilder: itemBuilder,
              itemCount: itemCount ?? 0,
            );

  /// Creates a [Column] layout with all items rendered eagerly.
  static Widget Function({required Widget? Function(BuildContext, int) itemBuilder, int? itemCount}) column(
    BuildContext context, {
    double gap = 0.0,
    Widget? Function(BuildContext, int)? separatorBuilder,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) =>
      ({required itemBuilder, itemCount}) => Column(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisAlignment: mainAxisAlignment,
            mainAxisSize: mainAxisSize,
            spacing: gap,
            children: List.generate(
                itemCount ?? 0,
                (index) => switch (index) {
                      _ when separatorBuilder != null => [
                          separatorBuilder(context, index),
                          itemBuilder(context, index),
                        ],
                      _ => [itemBuilder(context, index)]
                    }).expand((element) => element).whereType<Widget>().toList(growable: false),
          );

  /// Creates a [Row] layout with all items rendered eagerly.
  static Widget Function({required Widget? Function(BuildContext, int) itemBuilder, int? itemCount}) row(
    BuildContext context, {
    double gap = 0.0,
    Widget? Function(BuildContext, int)? separatorBuilder,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) =>
      ({required itemBuilder, itemCount}) => Row(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisAlignment: mainAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: List.generate(
              itemCount ?? 0,
              (index) => switch (index) {
                _ when separatorBuilder != null => [separatorBuilder(context, index), itemBuilder(context, index)],
                _ => [itemBuilder(context, index)],
              },
            ).expand((element) => element).whereType<Widget>().toList(growable: false),
          );
}
