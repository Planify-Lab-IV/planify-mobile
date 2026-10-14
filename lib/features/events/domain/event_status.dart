enum EventStatus {
  active,
  confirmed,
  cancelled;

  bool get isCancelled => this == EventStatus.cancelled;
  bool get isConfirmed => this == EventStatus.confirmed;
  bool get isActive => this == EventStatus.active;
}
