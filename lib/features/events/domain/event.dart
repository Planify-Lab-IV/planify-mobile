import 'event_status.dart';

class Event {
  final String id;
  final String name;
  final String location;
  final String organizerId;
  final EventStatus status;
  final String? date;

  const Event({
    required this.id,
    required this.name,
    required this.location,
    required this.organizerId,
    this.status = EventStatus.active,
    this.date,
  });

  bool get isCancelled => status.isCancelled;
  bool get isActive => status.isActive;

  Event copyWith({
    String? id,
    String? name,
    String? location,
    String? organizerId,
    EventStatus? status,
    String? date,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
      status: status ?? this.status,
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
          status == other.status &&
          date == other.date;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      location.hashCode ^
      organizerId.hashCode ^
      status.hashCode ^
      date.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, name: $name, location: $location, organizerId: $organizerId, status: $status, date: $date)';
  }
}
