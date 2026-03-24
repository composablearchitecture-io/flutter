import 'package:composable_architecture_core/src/utils/cancellable_operation.dart';

typedef EffectID = String;

class CancellableEffectHandler {
  var map = <EffectID, List<CancelableOperation>>{};

  void register(
    EffectID id,
    CancelableOperation cancelable,
    bool cancelInFlight,
  ) {
    if (cancelInFlight) {
      dispose(
        id,
        shouldCancel: cancelInFlight,
      );
    }
    if (!map.containsKey(id)) {
      map[id] = [];
    }
    map[id]!.add(cancelable);
  }

  void dispose(EffectID id, {bool shouldCancel = true}) {
    var res = map[id];
    if (shouldCancel) {
      res?.forEach((e) => e.cancel());
    }
    remove(id);
  }

  void remove(EffectID id) {
    map.remove(id);
  }

  bool isUnique(EffectID id) {
    return (map[id] ?? []).where((element) => !element.isCompleted && !element.isCanceled).isEmpty;
  }
}
