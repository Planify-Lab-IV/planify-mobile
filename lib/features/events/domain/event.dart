import 'event_status.dart';

class Event {
  final String id;
  final String name;
  final String location;
  final String organizerId;
  final String groupId;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime? date;

  const Event({
    required this.id,
    required this.name,
    required this.location,
    required this.organizerId,
    required this.groupId,
    this.status = EventStatus.active,
    required this.createdAt,
    this.date,
  });

  bool get isCancelled => status.isCancelled;
  bool get isActive => status.isActive;

  Event copyWith({
    String? id,
    String? name,
    String? location,
    String? organizerId,
    String? groupId,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? date,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          location == other.location &&
          organizerId == other.organizerId &&
          groupId == other.groupId &&
          status == other.status &&
          createdAt == other.createdAt &&
          date == other.date;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      location.hashCode ^
      organizerId.hashCode ^
      groupId.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      date.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, name: $name, location: $location, organizerId: $organizerId, groupId: $groupId, status: $status, createdAt: $createdAt, date: $date)';
  }
}
