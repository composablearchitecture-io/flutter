/// Flutter bindings for the Composable Architecture.
///
/// Re-exports everything from [composable_architecture_core] and adds
/// Flutter-specific widgets for connecting stores to the widget tree.
///
/// ## Widgets
///
/// - [WithStore] - Connects a [Store] to the widget tree with reactive rebuilds.
/// - [ForEachStore] - Renders a collection with per-item scoped stores.
/// - [IfLetStore] - Conditionally renders based on nullable state.
/// - [SwitchStore] - Renders based on the runtime type of state.
///
/// ## Utilities
///
/// - [IsEqualUtils] - Equality helpers for controlling rebuilds.
/// - [IterableBuilder] - Layout factories for [ForEachStore].
/// - [DependencyProvider] / [Dependency] - Dependency injection.
/// - [TextEditingControllerBuilder] - Two-way text field binding.
///
/// ## App Builders
///
/// For Material or Cupertino app integration with platform event handling,
/// import the sub-libraries:
///
/// ```dart
/// import 'package:composable_architecture_flutterw/material.dart';
/// import 'package:composable_architecture_flutterw/cupertino.dart';
/// ```
library;

export 'package:composable_architecture_core/composable_architecture_core.dart';

export 'src/with_store.widget.dart';
export 'src/for_each_store.widget.dart';
export 'src/if_let_store.widget.dart';
export 'src/switch_store.widget.dart';
export 'src/utils/is_equal_utils.dart';
export 'src/utils/for_each_utils.dart';
export 'src/utils/dependency.dart';
export 'src/builders/text_editing_controller_builder.dart';
