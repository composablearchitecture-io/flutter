import 'dart:async';
import 'dart:isolate';

import 'package:composable_architecture_core/src/utils/cancellable_operation.dart';
import 'package:composable_architecture_core/src/utils/scheduler.dart';

/// Unique string identifier for cancellable effects.
///
/// Used with [Effect.cancellable] and [Effect.cancel] to register and
/// cancel in-flight effects by name.
typedef EffectID = String;

/// Callback invoked to emit a [value] from an effect back to the store.
typedef EmitCallback<Value> = void Function(Value value);

/// Callback invoked to dispose of or cancel a registered effect.
///
/// If [id] is provided, disposes the effect registered under that ID.
/// If [shouldCancel] is `true` (the default), the underlying operation
/// is cancelled.
typedef DisposeCallback = void Function({EffectID? id, bool shouldCancel});

/// Callback invoked to register a [CancelableOperation] with the store's
/// effect lifecycle manager.
///
/// If [cancelInFlight] is `true`, any existing operation under the same
/// [id] is cancelled before registering the new one.
typedef RegisterCallback = void Function(
  CancelableOperation cancellable, {
  EffectID? id,
  bool cancelInFlight,
});

/// Callback that checks whether an effect should still emit.
///
/// Returns `true` if the effect is still active (not cancelled).
typedef GuardCallback = bool Function({EffectID? id});

/// The handler record provided to [Effect.run] that connects the effect
/// to the store's action dispatch, cancellation, and lifecycle systems.
typedef EffectHandler<Value> = ({
  EmitCallback<Value> emit,
  RegisterCallback register,
  DisposeCallback dispose,
  GuardCallback guard
});

/// Describes a unit of work that can emit values, be cancelled, or compose
/// with other units to form more elaborate workflows.
///
/// Example:
/// ```dart
/// final loadUser = Effect.task(() async => await api.fetchUser());
/// final cancellable = loadUser.cancellable(id: "user");
/// final debounced = cancellable.debounce(
///   id: "user",
///   interval: const Duration(milliseconds: 300),
/// );
/// ```
sealed class Effect<Value> {
  const Effect._();

  /// Represents the absence of work. Running this effect completes
  /// immediately without emitting values or registering cancellations.
  ///
  /// Example:
  /// ```dart
  /// final noOp = Effect<void>.none();
  /// ```
  const factory Effect.none() = NoneEffect;

  /// Emits [value] synchronously when the effect is run. This is useful for
  /// sending immediate feedback without scheduling asynchronous work.
  ///
  /// Example:
  /// ```dart
  /// final effect = Effect.value("Hello");
  /// ```
  const factory Effect.value(Value value) = ValueEffect<Value>;

  /// Runs every effect in [effects] concurrently and merges their emissions
  /// into a single effect. Completion occurs once all nested effects finish.
  ///
  /// Example:
  /// ```dart
  /// final merged = Effect.merge(effects: [
  ///   Effect.value(1),
  ///   Effect.task(() async => await fetchRemoteValue()),
  /// ]);
  /// ```
  const factory Effect.merge({required Iterable<Effect<Value>> effects}) = MergedEffect<Value>;

  /// Executes the supplied [effects] sequentially. Each effect starts only
  /// after the previous one completes, preserving deterministic ordering.
  ///
  /// Example:
  /// ```dart
  /// final chained = Effect.concatenate(effects: [
  ///   Effect.value("first"),
  ///   Effect.delayed(const Duration(milliseconds: 200), () => "second"),
  /// ]);
  /// ```
  const factory Effect.concatenate({required Iterable<Effect<Value>> effects}) = ConcatenatedEffect<Value>;

  /// Wraps an asynchronous computation. The [future] builder is invoked when
  /// the effect runs, optionally inside a new isolate. Errors can be mapped to
  /// fallback values via [onError].
  ///
  /// Example:
  /// ```dart
  /// final loadSettings = Effect.task(() async => await repository.fetchSettings());
  /// ```
  const factory Effect.task(
    Future<Value> Function() future, {
    bool runInIsolate,
    Value Function(Object error, StackTrace stackTrace)? onError,
  }) = FutureEffect<Value>;

  /// Emits a value on every [interval] using the synchronous [computation].
  /// Optional callbacks allow consumers to provide completion or error values,
  /// or to opt into canceling the subscription when an error occurs.
  ///
  /// Example:
  /// ```dart
  /// final ticker = Effect.periodic(
  ///   const Duration(seconds: 1),
  ///   (count) => "tick $count",
  /// );
  /// ```
  factory Effect.periodic(
    Duration interval,
    Value Function(int computationCount) computation, {
    Value Function()? onDone,
    Value Function(Object error, StackTrace stackTrace)? onError,
    bool? cancelOnError,
  }) =>
      Effect.stream(
        stream: Stream.periodic(interval, computation),
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError,
      );

  /// Asynchronous counterpart to [Effect.periodic]. The [computation] can
  /// perform suspending work before yielding each value.
  ///
  /// Example:
  /// ```dart
  /// final asyncTicker = Effect.asyncPeriodic(
  ///   const Duration(seconds: 1),
  ///   (count) async => await loadFrame(count),
  /// );
  /// ```
  factory Effect.asyncPeriodic(
    Duration interval,
    Future<Value> Function(int computationCount) computation, {
    Value Function()? onDone,
    Value Function(Object error, StackTrace stackTrace)? onError,
    bool? cancelOnError,
  }) =>
      Effect.stream(
        stream: Stream.periodic(interval, computation).asyncMap((e) async => await e),
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError,
      );

  /// Bridges any Dart [Stream] into the effect system. Emissions, completion,
  /// and errors are forwarded through the provided callbacks.
  ///
  /// Example:
  /// ```dart
  /// final fromStream = Effect.stream(stream: controller.stream);
  /// ```
  const factory Effect.stream({
    required Stream<Value> stream,
    Value Function()? onDone,
    Value Function(Object error, StackTrace stackTrace)? onError,
    bool? cancelOnError,
  }) = StreamEffect<Value>;

  /// Requests cancellation for any in-flight effect registered with [id]. This
  /// is the counterpart to [Effect.cancellable].
  ///
  /// Example:
  /// ```dart
  /// final cancelSearch = Effect<void>.cancel(id: "search");
  /// ```
  const factory Effect.cancel({required EffectID id}) = CancelEffect<Value>;

  /// Runs the synchronous [runner] immediately when the effect is executed and
  /// emits its return value. Errors can be transformed via [onError].
  ///
  /// Example:
  /// ```dart
  /// final generateId = Effect.run(() => uuid.v4());
  /// ```
  const factory Effect.run(
    Value Function() runner, {
    Value Function(Object error, StackTrace stackTrace)? onError,
  }) = RunEffect<Value>;

  /// Lazily constructs and subscribes to a stream returned by [stream] each
  /// time the effect runs. Useful when each invocation requires a new stream
  /// subscription.
  ///
  /// Example:
  /// ```dart
  /// final socketEffect = Effect.streamTask(() => socket.connect());
  /// ```
  factory Effect.streamTask(
    Stream<Value> Function() stream, {
    Value Function()? onDone,
    Value Function(Object error, StackTrace stackTrace)? onError,
    bool cancelOnError = true,
  }) =>
      Effect.stream(
        stream: stream(),
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError,
      );

  /// Delays executing [computation] by [duration] using the default scheduler
  /// and emits the returned value once the delay completes.
  ///
  /// Example:
  /// ```dart
  /// final reminder = Effect.delayed(
  ///   const Duration(seconds: 5),
  ///   () => "Time's up!",
  /// );
  /// ```
  factory Effect.delayed(Duration duration, Value Function() computation) =>
      delayedWithScheduler(duration, computation, defaultScheduler);

  /// Scheduler-aware variant of [Effect.delayed] that allows a custom
  /// [scheduler] and [interval] representation.
  ///
  /// Example:
  /// ```dart
  /// final delayed = Effect.delayedWithScheduler(
  ///   const Duration(milliseconds: 100),
  ///   () => 42,
  ///   defaultScheduler,
  /// );
  /// ```
  static Effect<Value> delayedWithScheduler<Value, Time, Interval>(
    Interval interval,
    Value Function() computation,
    Scheduler<Time, Interval> scheduler,
  ) =>
      Effect.task(() => scheduler.delayed(interval, computation));

  /// Associates this effect with [id] so that it can be cancelled later.
  /// Setting [cancelInFlight] to `true` cancels any currently running effect
  /// that uses the same identifier before starting this one.
  ///
  /// Example:
  /// ```dart
  /// final cancellableSearch = searchEffect.cancellable(id: "search", cancelInFlight: true);
  /// ```
  Effect<Value> cancellable({
    required EffectID id,
    bool cancelInFlight = false,
  }) =>
      CancellableEffect(id: id, effect: this, cancelInFlight: cancelInFlight);

  /// Convenience helper for sequencing this effect with [effect]. Both effects
  /// run one after the other, preserving emission order.
  ///
  /// Example:
  /// ```dart
  /// final combined = Effect.value("A").concatenate(effect: Effect.value("B"));
  /// ```
  Effect<Value> concatenate({required Effect<Value> effect}) => Effect.concatenate(effects: [this, effect]);

  /// Transforms emitted values using [mapper] before forwarding them to the
  /// reducer or downstream effect handler.
  ///
  /// Example:
  /// ```dart
  /// final strings = Effect.value(1).map((n) => "Number $n");
  /// ```
  Effect<NewValue> map<NewValue>(NewValue Function(Value value) mapper) =>
      MappedEffect<NewValue, Value>(effect: this, mapping: mapper);

  /// For each emitted value, invokes [mapper] to create another effect and
  /// flattens the resulting sequence into a single stream of values.
  ///
  /// Example:
  /// ```dart
  /// final search = queryEffect.flatMap((query) => performSearch(query));
  /// ```
  Effect<NewValue> flatMap<NewValue>(
    Effect<NewValue> Function(Value value) mapper,
  ) =>
      FlatMappedEffect<NewValue, Value>(effect: this, mapping: mapper);

  /// Delays emissions by [duration] on the default scheduler, allowing debounced
  /// or scheduled work without manually handling timers.
  ///
  /// Example:
  /// ```dart
  /// final delayedValue = Effect.value("update").delay(const Duration(milliseconds: 50));
  /// ```
  Effect<Value> delay(Duration duration) => delayWithScheduler(duration, defaultScheduler);

  /// Scheduler-aware delay helper that uses the provided [scheduler] to pause
  /// for [interval] before running the wrapped effect.
  ///
  /// Example:
  /// ```dart
  /// final delayedEffect = effect.delayWithScheduler(
  ///   const Duration(milliseconds: 10),
  ///   customScheduler,
  /// );
  /// ```
  Effect<Value> delayWithScheduler<Time, Interval>(
    Interval interval,
    Scheduler<Time, Interval> scheduler,
  ) =>
      DelayEffect(this, interval, scheduler);

  /// Runs the effect but suppresses any emitted values. Useful for fire-and-
  /// forget operations where only the side effects matter.
  ///
  /// Example:
  /// ```dart
  /// final logEffect = Effect.run(() => logger.info("clicked"));
  /// final fireAndForget = logEffect.fireAndForget<void>();
  /// ```
  Effect<NewValue> fireAndForget<NewValue>() => FireAndForgetEffect<NewValue>(effect: this);

  /// Executes the effect immediately with the supplied [handler]. Each effect
  /// implementation defines how it schedules work, emits values, and registers
  /// disposables.
  Future<void> run(
    EffectHandler<Value> handler,
  );

  /// Debounces emissions by delaying them until no new values have arrived for
  /// the specified [interval]. Uses the default scheduler for timing.
  ///
  /// Example:
  /// ```dart
  /// final debouncedSearch = searchEffect.debounce(
  ///   id: "search",
  ///   interval: const Duration(milliseconds: 300),
  /// );
  /// ```
  Effect<Value> debounce({required String id, required Duration interval}) => debounceWithScheduler(
        id: id,
        interval: interval,
        scheduler: defaultScheduler,
      );

  /// Scheduler-aware variant of [Effect.debounce] that uses the provided
  /// [scheduler]. The same [id] is reused to cancel pending debounced work.
  ///
  /// Example:
  /// ```dart
  /// final debounced = effect.debounceWithScheduler(
  ///   id: "search",
  ///   interval: const Duration(milliseconds: 200),
  ///   scheduler: customScheduler,
  /// );
  /// ```
  Effect<Value> debounceWithScheduler<Time, Interval>({
    required String id,
    required Interval interval,
    required Scheduler<Time, Interval> scheduler,
  }) {
    return switch (this) {
      NoneEffect _ => this,
      _ => delayWithScheduler(interval, scheduler).cancellable(id: id, cancelInFlight: true),
    };
  }

  /// Throttles emissions so that values are produced no more frequently than
  /// [interval]. The default scheduler controls the timing, and [direction]
  /// determines whether leading or trailing values are emitted.
  ///
  /// Example:
  /// ```dart
  /// final throttled = effect.throttle(
  ///   id: "scroll",
  ///   interval: const Duration(milliseconds: 300),
  /// );
  /// ```
  Effect<Value> throttle({
    required EffectID id,
    required Duration interval,
    ThrottleDirection direction = ThrottleDirection.leading,
    bool emitFirst = true,
  }) =>
      throttleWithScheduler(
        id: id,
        interval: interval,
        scheduler: defaultScheduler,
        direction: direction,
        emitFirst: emitFirst,
      );

  /// Scheduler-aware throttle helper that allows custom timing via [scheduler]
  /// and fine-grained control over leading/trailing emission behavior.
  ///
  /// Example:
  /// ```dart
  /// final throttled = effect.throttleWithScheduler(
  ///   id: "scroll",
  ///   interval: const Duration(milliseconds: 100),
  ///   scheduler: customScheduler,
  ///   direction: ThrottleDirection.trailing,
  ///   emitFirst: false,
  /// );
  /// ```
  Effect<Value> throttleWithScheduler<Time, Interval>({
    required EffectID id,
    required Interval interval,
    required Scheduler<Time, Interval> scheduler,
    required ThrottleDirection direction,
    required bool emitFirst,
  }) {
    return switch (this) {
      NoneEffect _ => this,
      _ => flatMap<Value>((value) {
          final lastThrottleTime = scheduler.getThrottleTimes(id);
          if (lastThrottleTime == null) {
            scheduler.setThrottleTimes(id, scheduler.now);
            return emitFirst || direction == ThrottleDirection.leading ? Effect.value(value) : Effect.none();
          } else {
            final (isGreater, remaining) = scheduler.distance(last: lastThrottleTime, interval: interval);

            switch (direction) {
              case ThrottleDirection.leading:
                if (isGreater) {
                  scheduler.setThrottleTimes(id, scheduler.now);
                  return Effect.value(value);
                } else {
                  return Effect.none();
                }
              case ThrottleDirection.trailing:
                scheduler.setThrottleTimes(id, scheduler.now);
                return Effect.delayedWithScheduler(
                  isGreater ? interval : remaining,
                  () {
                    scheduler.setThrottleTimes(id, scheduler.now);
                    return value;
                  },
                  scheduler,
                );
            }
          }
        }).cancellable(id: id, cancelInFlight: true)
    };
  }
}

/// Controls whether [Effect.throttle] emits on the leading or trailing edge
/// of the throttle interval.
enum ThrottleDirection {
  /// Emit the first value immediately, then ignore until the interval passes.
  leading,

  /// Delay emission until the interval passes, emitting the latest value.
  trailing,
}

/// An effect that performs no work. See [Effect.none].
final class NoneEffect<Value> extends Effect<Value> {
  const NoneEffect() : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) async {}
}

/// An effect that synchronously emits a single value. See [Effect.value].
final class ValueEffect<Value> extends Effect<Value> {
  final Value value;

  const ValueEffect(this.value) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) async {
    if (!handler.guard()) return;
    handler.emit(value);
  }
}

/// An effect that runs multiple effects concurrently. See [Effect.merge].
final class MergedEffect<Value> extends Effect<Value> {
  final Iterable<Effect<Value>> effects;

  const MergedEffect({required this.effects}) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) async {
    if (!handler.guard()) return;
    return Future.wait(effects.map((e) => e.run(handler))).then((_) => ());
  }
}

/// An effect that runs multiple effects sequentially. See [Effect.concatenate].
final class ConcatenatedEffect<Value> extends Effect<Value> {
  final Iterable<Effect<Value>> effects;

  const ConcatenatedEffect({required this.effects}) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) async {
    if (!handler.guard()) return;
    for (final effect in effects) {
      await effect.run(handler);
    }
  }
}

/// An effect that wraps an asynchronous computation. See [Effect.task].
final class FutureEffect<Value> extends Effect<Value> {
  final Future<Value> Function() future;
  final bool runInIsolate;
  final Value Function(Object error, StackTrace stackTrace)? onError;

  const FutureEffect(
    this.future, {
    this.runInIsolate = false,
    this.onError,
  }) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) {
    if (!handler.guard()) return Future.value();
    late final CancelableOperation cancellable;
    cancellable = CancelableOperation.fromFuture(
      (runInIsolate ? Isolate.run(future) : future()).catchError((Object error, StackTrace stackTrace) {
        assert(
          onError != null,
          "onError should not be null, Unhandled: $error\n$stackTrace",
        );
        return onError!.call(error, stackTrace);
      }),
    ).then(handler.emit);
    handler.register(cancellable);
    return cancellable.value;
  }
}

/// An effect that delays execution by an interval before running the wrapped
/// effect. See [Effect.delay].
final class DelayEffect<Value, Time, Interval> extends Effect<Value> {
  final Effect<Value> effect;
  final Interval interval;
  final Scheduler<Time, Interval> scheduler;

  DelayEffect(this.effect, this.interval, this.scheduler) : super._();

  @override
  Future<void> run(EffectHandler<Value> handler) {
    if (!handler.guard()) return Future.value();
    Future<void> future = scheduler.delayed(interval, () {});
    final cancellable = CancelableOperation.fromFuture(
      future,
    ).then(
      (_) => effect.run(handler),
    );
    handler.register(cancellable);
    return cancellable.value;
  }
}

CancelableOperation<void> fromSubscription(
  StreamSubscription<void> subscription, {
  bool? cancelOnError,
}) {
  var completer = CancelableCompleter<void>(onCancel: subscription.cancel);
  subscription.onDone(completer.complete);
  if (cancelOnError ?? false) {
    subscription.onError((Object error, StackTrace stackTrace) {
      subscription.cancel().whenComplete(() {
        completer.completeError(error, stackTrace);
      });
    });
  }
  return completer.operation;
}

/// An effect that bridges a Dart [Stream] into the effect system.
/// See [Effect.stream].
final class StreamEffect<Value> extends Effect<Value> {
  final Stream<Value> stream;
  final Value Function()? onDone;
  final Value Function(Object error, StackTrace stackTrace)? onError;
  final bool? cancelOnError; // Default value is false

  const StreamEffect({
    required this.stream,
    this.onDone,
    this.onError,
    this.cancelOnError,
  }) : super._();

  void Function(Object error, StackTrace stack) handleError(
    EffectHandler<Value> handler,
  ) {
    return onError != null ? (p0, p1) => handler.emit(onError!(p0, p1)) : (p0, p1) {};
  }

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) {
    if (!handler.guard()) return Future.value();
    final cancellable = fromSubscription(
      stream.listen(
        handler.emit,
        cancelOnError: cancelOnError,
        onError: handleError(handler),
      ),
      cancelOnError: cancelOnError,
    ).then(
      (_) {
        if (onDone != null) {
          handler.emit(onDone!());
        }
        handler.dispose(shouldCancel: false);
      },
      onError: handleError(handler),
    );
    handler.register(cancellable);
    return cancellable.value;
  }
}

/// An effect that associates the wrapped effect with an [EffectID] for
/// cancellation management. See [Effect.cancellable].
final class CancellableEffect<Value> extends Effect<Value> {
  final EffectID id;
  final Effect<Value> effect;
  final bool cancelInFlight;

  const CancellableEffect({
    required this.id,
    required this.effect,
    required this.cancelInFlight,
  }) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) {
    if (!handler.guard()) return Future.value();
    return effect.run(
      (
        emit: handler.emit,
        dispose: ({id, shouldCancel = true}) => handler.dispose(id: this.id, shouldCancel: shouldCancel),
        register: (cancellable, {cancelInFlight = false, id}) => handler.register(
              cancellable,
              id: this.id,
              cancelInFlight: this.cancelInFlight,
            ),
        guard: handler.guard,
      ),
    );
  }
}

/// An effect that cancels a previously registered in-flight effect by ID.
/// See [Effect.cancel].
final class CancelEffect<Value> extends Effect<Value> {
  final EffectID id;

  const CancelEffect({required this.id}) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) async {
    if (!handler.guard()) return;
    handler.dispose(id: id, shouldCancel: true);
  }
}

/// An effect that transforms emitted values through a mapping function.
/// See [Effect.map].
final class MappedEffect<Value, PrevValue> extends Effect<Value> {
  final Effect<PrevValue> effect;
  final Value Function(PrevValue) mapping;

  const MappedEffect({required this.effect, required this.mapping}) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) {
    if (!handler.guard()) return Future.value();
    return effect.run(
      (
        emit: (value) => handler.emit(mapping(value)),
        dispose: handler.dispose,
        register: handler.register,
        guard: handler.guard,
      ),
    );
  }
}

/// An effect that flat-maps emitted values into new effects.
/// See [Effect.flatMap].
final class FlatMappedEffect<Value, PrevValue> extends Effect<Value> {
  final Effect<PrevValue> effect;
  final Effect<Value> Function(PrevValue value) mapping;

  const FlatMappedEffect({required this.effect, required this.mapping}) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) {
    if (!handler.guard()) return Future.value();
    return effect.run(
      (
        emit: (value) => mapping(value).run(handler),
        dispose: handler.dispose,
        register: handler.register,
        guard: handler.guard,
      ),
    );
  }
}

/// An effect that runs the wrapped effect but suppresses all emissions.
/// See [Effect.fireAndForget].
final class FireAndForgetEffect<Value> extends Effect<Value> {
  final Effect<dynamic> effect;

  const FireAndForgetEffect({required this.effect}) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) {
    if (!handler.guard()) return Future.value();
    return effect.run(
      (
        emit: (_) {},
        dispose: handler.dispose,
        register: handler.register,
        guard: handler.guard,
      ),
    );
  }
}

/// An effect that runs a synchronous computation and emits the result.
/// See [Effect.run].
final class RunEffect<Value> extends Effect<Value> {
  final Value Function() runner;
  final Value Function(Object error, StackTrace stackTrace)? onError;

  const RunEffect(this.runner, {this.onError}) : super._();

  @override
  Future<void> run(
    EffectHandler<Value> handler,
  ) async {
    if (!handler.guard()) return;
    late Value result;
    try {
      result = runner();
    } catch (e, stackTrace) {
      assert(
        onError != null,
        "When error can happens, onError should not be null",
      );
      result = onError!(e, stackTrace);
    }
    handler.emit(result);
  }
}
