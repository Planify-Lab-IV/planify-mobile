class SlotHeatmapDto {
  final int weekDay;
  final int hourBlock;
  final int availableCount;

  SlotHeatmapDto({
    required this.weekDay,
    required this.hourBlock,
    required this.availableCount,
  }) {
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
    if (availableCount < 0) {
      throw ArgumentError.value(
        availableCount,
        'availableCount',
        'must be greater than or equal to 0',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotHeatmapDto &&
          weekDay == other.weekDay &&
          hourBlock == other.hourBlock &&
          availableCount == other.availableCount;

  @override
  int get hashCode => Object.hash(weekDay, hourBlock, availableCount);
}
