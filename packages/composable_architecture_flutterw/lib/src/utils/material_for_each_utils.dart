import 'package:flutter/material.dart';

/// Material Design iterable builders for [ForEachStore].
///
/// These builders use Material-specific widgets that are not available
/// in the base widgets library.
class MaterialIterableBuilder {
  /// Creates a Material [ReorderableListView.builder] for drag-to-reorder
  /// lists.
  static Widget Function({
    required Widget? Function(BuildContext, int) itemBuilder,
    int? itemCount,
  }) reorderableList({
    required void Function(int oldIndex, int newIndex) onReorder,
    double? autoScrollerVelocityScalar,
    int? Function(Key)? findChildIndexCallback,
    void Function(int)? onReorderEnd,
    void Function(int)? onReorderStart,
    Widget? prototypeItem,
    Widget Function(Widget, int, Animation<double>)? proxyDecorator,
    bool buildDefaultDragHandles = true,
    EdgeInsets? padding,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) =>
      ({required Widget? Function(BuildContext, int) itemBuilder, int? itemCount}) => ReorderableListView.builder(
            itemBuilder: (context, index) => itemBuilder(context, index) ?? Container(),
            itemCount: itemCount ?? 0,
            onReorder: onReorder,
            autoScrollerVelocityScalar: autoScrollerVelocityScalar,
            onReorderEnd: onReorderEnd,
            onReorderStart: onReorderStart,
            prototypeItem: prototypeItem,
            proxyDecorator: proxyDecorator,
            buildDefaultDragHandles: buildDefaultDragHandles,
            padding: padding,
            keyboardDismissBehavior: keyboardDismissBehavior,
            shrinkWrap: shrinkWrap,
            physics: physics,
          );
}
