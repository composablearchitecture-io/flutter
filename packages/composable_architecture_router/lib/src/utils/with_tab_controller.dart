import 'package:flutter/material.dart';
import 'package:composable_architecture_router/composable_architecture_router.dart';

class WithTabController extends StatefulWidget {
  final int length;
  final NestedNavigator nestedNavigator;
  final Widget Function(TabController controller) builder;
  final Widget? orElse;
  final bool cached;

  const WithTabController({
    Key? key,
    required this.length,
    required this.nestedNavigator,
    required this.builder,
    this.cached = false,
    this.orElse,
  }) : super(key: key);

  @override
  State<WithTabController> createState() => _WithTabControllerState();

  int get currentTab => switch (nestedNavigator) {
        TabNestedNavigator(:final currentTab) => currentTab,
        _ => 0,
      };
}

class _WithTabControllerState extends State<WithTabController> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Widget? _cached;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.length,
      initialIndex: widget.currentTab,
      vsync: this,
    );
    _tabController.addListener(() {
      // This mean that user has change the tab, scrolling
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant WithTabController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTab != widget.currentTab) {
      _tabController.animateTo(widget.currentTab);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nestedNavigator is! TabNestedNavigator && widget.orElse != null) {
      return widget.orElse!;
    }
    //TODO refactor this to handle resize
    return widget.cached ? (_cached ??= widget.builder(_tabController)) : widget.builder(_tabController);
  }
}
