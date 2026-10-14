enum EventStatus {
  active,
  confirmed,
  cancelled;

  static EventStatus fromApi(String value) => switch (value) {
    'active' => EventStatus.active,
    'confirmed' => EventStatus.confirmed,
    'cancelled' => EventStatus.cancelled,
    _ => throw ArgumentError.value(value, 'value', 'Unknown event status'),
  };

  bool get isCancelled => this == EventStatus.cancelled;
  bool get isConfirmed => this == EventStatus.confirmed;
  bool get isActive => this == EventStatus.active;
}
