import 'dart:math';

/// Callback invoked when an [Observable] emits a new value.
typedef OnChangeCallback<T> = void Function(T value);

/// A lightweight reactive primitive for observing value changes.
///
/// Unlike Dart [Stream]s, observables are synchronous and support operators
/// like [map], [distinct], and [when] for declarative transformations.
///
/// Obtain an observable from [Store.stateObservable] or
/// [Store.actionObservable].
///
/// ```dart
/// store.stateObservable
///   .map((state) => state.count)
///   .distinct()
///   .listen((count) => print(count));
/// ```
abstract class Observable<T> {
  /// Subscribes to value changes.
  ///
  /// Returns a subscription ID that can be passed to [cancel] to unsubscribe.
  /// If [fireImmediately] is `true` (the default), the callback is invoked
  /// immediately with the current value (if one exists).
  int listen(OnChangeCallback<T> callback, {bool fireImmediately = true});

  /// Cancels a subscription by its [id], as returned from [listen].
  void cancel(int id);

  /// Returns an observable that only emits when the value changes according
  /// to [isEqual] (defaults to `==`).
  ///
  /// Consecutive equal values are suppressed.
  Observable<T> distinct([bool Function(T a, T b)? isEqual]) {
    final eq = isEqual ?? (T a, T b) => a == b;
    return _DerivedObservable<T, T>(
      parent: this,
      handler: (value, emit, state) {
        if (!state.hasPrevious || !eq(state.previous as T, value)) {
          state.hasPrevious = true;
          state.previous = value;
          emit(value);
        }
      },
    );
  }

  /// Returns an observable that transforms each emitted value using
  /// [transform].
  Observable<R> map<R>(R Function(T value) transform) {
    return _DerivedObservable<T, R>(
      parent: this,
      handler: (value, emit, _) => emit(transform(value)),
    );
  }

  /// Returns an observable that only emits values satisfying [predicate].
  Observable<T> when(bool Function(T value) predicate) {
    return _DerivedObservable<T, T>(
      parent: this,
      handler: (value, emit, _) {
        if (predicate(value)) {
          emit(value);
        }
      },
    );
  }
}

class _DerivedState<T> {
  T? previous;
  bool hasPrevious = false;
}

class _DerivedObservable<S, T> extends Observable<T> {
  final Observable<S> _parent;
  final void Function(
    S value,
    OnChangeCallback<T> emit,
    _DerivedState<T> state,
  ) _handler;
  final List<_DerivedListener<S, T>> _listeners = [];

  _DerivedObservable({
    required Observable<S> parent,
    required void Function(
      S value,
      OnChangeCallback<T> emit,
      _DerivedState<T> state,
    ) handler,
  })  : _parent = parent,
        _handler = handler;

  @override
  int listen(OnChangeCallback<T> callback, {bool fireImmediately = true}) {
    final state = _DerivedState<T>();
    final parentId = _parent.listen(
      (value) {
        _handler(value, callback, state);
      },
      fireImmediately: fireImmediately,
    );
    final id = Random().nextInt(1 << 31);
    _listeners.add(_DerivedListener(id: id, parentId: parentId));
    return id;
  }

  @override
  void cancel(int id) {
    final index = _listeners.indexWhere((l) => l.id == id);
    if (index != -1) {
      final listener = _listeners.removeAt(index);
      _parent.cancel(listener.parentId);
    }
  }
}

class _DerivedListener<S, T> {
  final int id;
  final int parentId;

  _DerivedListener({required this.id, required this.parentId});
}
