/// Utility functions for comparing state values to determine whether a
/// widget rebuild is necessary.
///
/// Used as default [isEqual] parameters in [WithStore] and related widgets.
class IsEqualUtils {
  /// Compares using `==`. This is the default equality check for [WithStore].
  static bool stateAreEquals(dynamic previous, dynamic current) => previous == current;

  /// Always returns `true`, disabling rebuild optimization.
  ///
  /// Use this when the widget should never rebuild due to state changes
  /// (e.g., when using [WithStore.textEditingController] where the
  /// controller handles its own updates).
  static bool alwaysEquals(dynamic previous, dynamic current) => true;

  /// Compares two iterables element-by-element using [toID] to extract
  /// comparable identifiers.
  ///
  /// Returns `false` if lengths differ or any element IDs don't match.
  static bool listAreEquals<E, ID>(Iterable<E> previous, Iterable<E> current, ID Function(int index, E element) toID) {
    if (previous.length != current.length) {
      return false;
    }
    // Check if all elements are equal based on their IDs
    final previousIterator = previous.iterator;
    final currentIterator = current.iterator;
    var index = 0;

    while (previousIterator.moveNext() && currentIterator.moveNext()) {
      if (toID(index, previousIterator.current) != toID(index, currentIterator.current)) {
        return false;
      }
      index++;
    }
    return true;
  }
}
