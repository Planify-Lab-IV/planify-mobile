class Slot {
  final int weekDay;
  final int hourBlock;

  Slot({required this.weekDay, required this.hourBlock}) {
    if (weekDay < 0 || weekDay > 6) {
      throw ArgumentError.value(
        weekDay,
        'weekDay',
        'must be between 0 and 6',
      );
    }
    if (hourBlock < 0 || hourBlock > 23) {
      throw ArgumentError.value(
        hourBlock,
        'hourBlock',
        'must be between 0 and 23',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Slot &&
          weekDay == other.weekDay &&
          hourBlock == other.hourBlock;

  @override
  int get hashCode => Object.hash(weekDay, hourBlock);

  @override
  String toString() => 'Slot(weekDay: $weekDay, hourBlock: $hourBlock)';
}
