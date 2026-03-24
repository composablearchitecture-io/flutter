class ComposablePageArguments {
  final bool isFlattened;

  ComposablePageArguments({
    this.isFlattened = false,
  });

  ComposablePageArguments copyWith({bool? isFlattened}) =>
      ComposablePageArguments(isFlattened: isFlattened ?? this.isFlattened);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComposablePageArguments && isFlattened == other.isFlattened;

  @override
  int get hashCode => isFlattened.hashCode;

  @override
  String toString() => 'ComposablePageArguments(isFlattened: $isFlattened)';
}
