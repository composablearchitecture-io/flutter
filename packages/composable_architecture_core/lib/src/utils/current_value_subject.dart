import 'dart:math';

import 'package:composable_architecture_core/src/observable/observable.dart';

export 'package:composable_architecture_core/src/observable/observable.dart';

/// Internal listener entry pairing a callback with a subscription ID.
class Listener<T> {
  /// The callback to invoke on value changes.
  final OnChangeCallback<T> callback;

  /// Unique subscription identifier.
  final int id;

  /// Creates a listener.
  Listener({required this.callback, required this.id});
}

/// Configuration options for creating a [CurrentValueSubject].
class SubjectOptions {
  /// Callback invoked when the subject's last listener is cancelled.
  final void Function()? onCancel;

  /// Whether this subject is derived from another subject.
  /// Derived subjects cannot have values added directly.
  final bool isDerived;

  /// Creates subject options.
  const SubjectOptions({this.onCancel, this.isDerived = false});
}

/// An [Observable] that holds a current value and notifies listeners
/// when the value changes.
///
/// This is the concrete implementation of [Observable] used internally
/// by [Store] to manage state and action streams.
///
/// ## Creating a Subject
///
/// ```dart
/// final subject = CurrentValueSubject.create<int>(0);
/// subject.listen((value) => print(value)); // prints 0 immediately
/// subject.add(1); // prints 1
/// ```
///
/// ## Derived Subjects
///
/// Create a derived subject that projects a subset of the value:
///
/// ```dart
/// final name = subject.derive((user) => user.name);
/// ```
class CurrentValueSubject<T> extends Observable<T> {
  List<Listener<T>> listeners = [];
  void Function()? _onCancel;
  final bool _isDerived;
  T? _value;

  CurrentValueSubject._({T? initialValue, SubjectOptions? options})
      : _value = initialValue,
        _onCancel = options?.onCancel,
        _isDerived = options?.isDerived ?? false;

  /// The current value held by this subject.
  T get value => _value as T;

  /// Sets the cancellation callback. Can only be set once.
  set onCancel(void Function() value) {
    if (_onCancel != null) {
      throw Exception("Cannot set onCancel twice");
    }
    _onCancel = value;
  }

  /// Creates a subject with an initial [value].
  static CurrentValueSubject<T> create<T>(T value) =>
      CurrentValueSubject._(initialValue: value);

  /// Creates a subject without an initial value.
  static CurrentValueSubject<T> empty<T>() =>
      CurrentValueSubject._(initialValue: null);

  /// Emits a new [value] to all listeners.
  ///
  /// Throws if this is a derived subject. Use the parent subject instead.
  void add(T value) {
    if (_isDerived) {
      throw Exception("Cannot add value to derived subject");
    }
    _internalAdd(value);
  }

  void _internalAdd(T newValue) {
    _value = newValue;
    for (final listener in listeners) {
      listener.callback(newValue);
    }
  }

  /// Creates a derived subject that projects a subset of this subject's value.
  ///
  /// The derived subject updates whenever this subject updates, applying
  /// [deriveState] to produce its value. The derived subject cannot have
  /// values added directly.
  ///
  /// ```dart
  /// final nameSubject = userSubject.derive((user) => user.name);
  /// ```
  CurrentValueSubject<Derived> derive<Derived>(
    Derived Function(T state) deriveState,
  ) {
    final derivedSubject = CurrentValueSubject<Derived>._(
      initialValue: _value == null ? null : deriveState(_value as T),
      options: const SubjectOptions(isDerived: true),
    );
    final id = listen(
      (newValue) => derivedSubject._internalAdd(deriveState(newValue)),
    );
    derivedSubject.onCancel = () => cancel(id);
    return derivedSubject;
  }

  @override
  int listen(OnChangeCallback<T> callback, {bool fireImmediately = true}) {
    int id = Random().nextInt(1 << 31);
    listeners.add(Listener(callback: callback, id: id));
    if (_value != null && fireImmediately) {
      callback(_value as T);
    }
    return id;
  }

  @override
  void cancel(int id) {
    listeners.removeWhere((listener) => listener.id == id);
    _onCancel?.call();
  }

  /// Removes all listeners and clears the cancellation callback.
  void dispose() {
    listeners.clear();
    _onCancel = null;
  }
}
