class Slot {
  final int dayOfWeek;
  final int hour;

  Slot({required this.dayOfWeek, required this.hour}) {
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      throw ArgumentError.value(
        dayOfWeek,
        'dayOfWeek',
        'must be between 0 and 6',
      );
    }
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be between 0 and 23');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Slot && dayOfWeek == other.dayOfWeek && hour == other.hour;

  @override
  int get hashCode => Object.hash(dayOfWeek, hour);

  @override
  String toString() => 'Slot(dayOfWeek: $dayOfWeek, hour: $hour)';
}
