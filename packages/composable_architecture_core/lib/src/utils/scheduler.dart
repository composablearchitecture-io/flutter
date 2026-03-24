import 'package:composable_architecture_core/src/effect.dart';

abstract class Scheduler<Time, Interval> {
  const Scheduler();

  Time? getThrottleTimes(EffectID id);
  void setThrottleTimes(EffectID id, Time? time);

  Time get now;
  Future<T> delayed<T>(Interval interval, T Function() computation);
  (bool, Interval) distance({required Time last, required Interval interval});
}

class DefaultScheduler extends Scheduler<DateTime, Duration> {
  // NOTE: IDs are not cleaned up, so this could be a memory leak.
  final Map<EffectID, DateTime> _throttleTimes = {};

  DefaultScheduler();

  @override
  DateTime? getThrottleTimes(EffectID id) {
    return _throttleTimes[id];
  }

  @override
  void setThrottleTimes(EffectID id, DateTime? time) {
    if (time == null) {
      _throttleTimes.remove(id);
    } else {
      _throttleTimes[id] = time;
    }
  }

  @override
  DateTime get now => DateTime.now();

  @override
  Future<T> delayed<T>(Duration interval, T Function() computation) {
    return Future.delayed(interval, computation);
  }

  @override
  (bool, Duration) distance({required DateTime last, required Duration interval}) {
    final now = DateTime.now();
    final distance = now.difference(last);
    return (distance >= interval, interval - distance);
  }
}

final defaultScheduler = DefaultScheduler();
