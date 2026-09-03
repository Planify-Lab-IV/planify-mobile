enum EventStatus {
  active,
  cancelled;

  bool get isCancelled => this == EventStatus.cancelled;
  bool get isActive => this == EventStatus.active;
}
