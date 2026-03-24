class ActionBuffer<Action> {
  final List<Action> list = List.empty(growable: true);

  bool get isNotEmpty => list.isNotEmpty;

  void append(Action action) {
    list.add(action);
  }

  Action removeLast() {
    return list.removeLast();
  }
}
