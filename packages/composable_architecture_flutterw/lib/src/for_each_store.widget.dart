import 'package:flutter/widgets.dart';
import 'package:composable_architecture_core/composable_architecture_core.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_flutterw/src/utils/iterable_ext.dart';

/// Returns the IDs present in [previous] but not in [current].
///
/// Used internally by [ForEachStore] to clean up cached widgets for
/// removed elements.
Iterable<ID> deletedIds<ID, E>(
  Iterable<E> previous,
  Iterable<E> current,
  ID Function(int index, E element) toID,
) {
  final previousIds = previous.mapIndexed(toID).toSet();
  final currentIds = current.mapIndexed(toID).toSet();

  return previousIds.difference(currentIds);
}

/// A widget that renders each element of a collection with its own scoped
/// [Store].
///
/// Each item gets a scoped store derived from the parent store. Items are
/// cached by ID for performance - only new items trigger widget creation.
/// Removed items have their cached widgets cleaned up automatically.
///
/// ## Constructors
///
/// - [ForEachStore.indexed] - identifies items by their index in the collection.
/// - [ForEachStore.id] - identifies items by a custom ID function.
/// - [ForEachStore.indexedId] - provides both index and custom ID to the builder.
///
/// ## Example
///
/// ```dart
/// ForEachStore.id(
///   store: store,
///   getIterable: (state) => state.contacts,
///   embedAction: (id, action) => AppAction.contact(id, action),
///   toID: (contact) => contact.id,
///   iterableBuilder: IterableBuilder.listViewBuilder(),
///   builder: (context, contactStore, id) =>
///     ContactCard(store: contactStore),
/// );
/// ```
///
/// See also:
/// - [IterableBuilder] for layout builder factories
/// - [ForEachIterableReducer.forEach] for the corresponding reducer
class ForEachStore<ID, GlobalState, GlobalAction, ItemState, ItemAction> extends StatelessWidget {
  /// Builder function called for each item.
  final Widget Function(BuildContext context, Store<ItemState, ItemAction> store, ID id, int index, int itemCount)
      builder;

  /// The parent store containing the collection state.
  final Store<GlobalState, GlobalAction> store;

  /// Extracts the iterable collection from the global state.
  final Iterable<ItemState> Function(GlobalState state) getIterable;

  /// Embeds a local item action into the global action type.
  final GlobalAction Function(ID id, ItemAction localAction) embedAction;

  /// Extracts a unique ID from an item and its index.
  final ID Function(int index, ItemState state) toID;

  /// Factory that creates the layout widget (e.g., ListView, Column).
  ///
  /// Use [IterableBuilder] for pre-built layout factories.
  final Widget Function({
    required Widget? Function(BuildContext, int) itemBuilder,
    int? itemCount,
  }) iterableBuilder;

  /// Builder shown when the collection is empty. If `null`, an empty
  /// [Container] is rendered.
  final Widget Function(BuildContext)? onEmptyBuilder;

  final Map<ID, Widget> _cachedWidgets = {};

  ForEachStore._({
    Key? key,
    required this.store,
    required this.getIterable,
    required this.embedAction,
    required this.toID,
    required this.iterableBuilder,
    required this.builder,
    this.onEmptyBuilder,
  }) : super(key: key);

  /// Creates a [ForEachStore] that identifies items by their index.
  ///
  /// The builder receives the item's index and total count. Use this when
  /// items don't have stable unique identifiers.
  static ForEachStore<int, GlobalState, GlobalAction, ItemState, ItemAction>
      indexed<GlobalState, GlobalAction, ItemState, ItemAction>({
    required Widget Function(BuildContext context, Store<ItemState, ItemAction> store, int index, int itemCount)
        builder,
    required Store<GlobalState, GlobalAction> store,
    required Iterable<ItemState> Function(GlobalState state) getIterable,
    required GlobalAction Function(int index, ItemAction localAction) embedAction,
    required Widget Function({
      required Widget? Function(BuildContext, int) itemBuilder,
      int? itemCount,
    }) iterableBuilder,
    Widget Function(BuildContext)? onEmptyBuilder,
  }) =>
          ForEachStore._(
            store: store,
            getIterable: getIterable,
            embedAction: embedAction,
            toID: (index, state) => index,
            iterableBuilder: iterableBuilder,
            builder: (context, store, id, _, itemCount) => builder(context, store, id, itemCount),
            onEmptyBuilder: onEmptyBuilder,
          );

  /// Creates a [ForEachStore] that identifies items by a custom [toID]
  /// function.
  ///
  /// This is the most common constructor. Each item is cached by its ID,
  /// so only new items trigger widget creation.
  static ForEachStore<ID, GlobalState, GlobalAction, ItemState, ItemAction>
      id<ID, GlobalState, GlobalAction, ItemState, ItemAction>({
    required Widget Function(BuildContext context, Store<ItemState, ItemAction> store, ID id) builder,
    required Store<GlobalState, GlobalAction> store,
    required Iterable<ItemState> Function(GlobalState state) getIterable,
    required GlobalAction Function(ID id, ItemAction localAction) embedAction,
    required ID Function(ItemState state) toID,
    required Widget Function({
      required Widget? Function(BuildContext, int) itemBuilder,
      int? itemCount,
    }) iterableBuilder,
    Widget Function(BuildContext)? onEmptyBuilder,
  }) =>
          ForEachStore._(
            store: store,
            getIterable: getIterable,
            embedAction: embedAction,
            toID: (index, ItemState state) => toID(state),
            iterableBuilder: iterableBuilder,
            builder: (context, store, id, _, __) => builder(context, store, id),
            onEmptyBuilder: onEmptyBuilder,
          );

  /// Creates a [ForEachStore] that provides both a custom ID and the index
  /// to the builder.
  static ForEachStore<ID, GlobalState, GlobalAction, ItemState, ItemAction>
      indexedId<ID, GlobalState, GlobalAction, ItemState, ItemAction>({
    required Widget Function(BuildContext context, Store<ItemState, ItemAction> store, ID id, int index, int itemCount)
        builder,
    required Store<GlobalState, GlobalAction> store,
    required Iterable<ItemState> Function(GlobalState state) getIterable,
    required GlobalAction Function(ID id, ItemAction localAction) embedAction,
    required ID Function(ItemState state) toID,
    required Widget Function({
      required Widget? Function(BuildContext, int) itemBuilder,
      int? itemCount,
    }) iterableBuilder,
    Widget Function(BuildContext)? onEmptyBuilder,
  }) =>
          ForEachStore._(
            store: store,
            getIterable: getIterable,
            embedAction: embedAction,
            toID: (index, ItemState state) => toID(state),
            iterableBuilder: iterableBuilder,
            builder: builder,
            onEmptyBuilder: onEmptyBuilder,
          );

  /// Builds and caches widgets for any new items not yet in the cache.
  void populateCache(BuildContext context, Iterable<ItemState> items) {
    var index = 0;
    for (var itemState in items) {
      final itemId = toID(index++, itemState);
      if (!_cachedWidgets.containsKey(itemId)) {
        _cachedWidgets[itemId] = builder(
          context,
          store.scope(
            toLocalState: (globalState) {
              try {
                return getIterable(globalState).firstWhereIndexed((index, element) => toID(index, element) == itemId);
              } catch (e) {
                return itemState;
              }
            },
            toGlobalAction: (ItemAction localAction) => embedAction(
              itemId,
              localAction,
            ),
          ),
          itemId,
          index,
          items.length,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WithStore.observe(
      isEqual: (previous, current) {
        final isEqual = IsEqualUtils.listAreEquals(previous, current, toID);
        if (!isEqual) {
          // Remove cached widgets for deleted IDs
          for (final deletedID in deletedIds<ID, ItemState>(previous, current, toID)) {
            _cachedWidgets.remove(deletedID);
          }
        }
        return isEqual;
      },
      observe: (state) => getIterable(state),
      store: store,
      builder: (items, send, context) {
        final itemsLength = items.length;
        if (itemsLength == 0) {
          return onEmptyBuilder?.call(context) ?? Container();
        } else {
          populateCache(context, items);
          return iterableBuilder(
            itemBuilder: (context, index) {
              final id = toID(index, items.elementAt(index));
              return Container(
                key: ValueKey(id),
                child: _cachedWidgets[id]!,
              );
            },
            itemCount: items.length,
          );
        }
      },
    );
  }
}
