import 'package:flutter/foundation.dart';
import 'event_participant.dart';
import 'event_status.dart';

class Event {
  final String id;
  final String name;
  final String location;
  final String organizerId;
  final String groupId;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? date;
  final List<EventParticipant> participants;

  const Event({
    required this.id,
    required this.name,
    required this.location,
    required this.organizerId,
    required this.groupId,
    this.status = EventStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.date,
    this.participants = const [],
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
    DateTime? updatedAt,
    DateTime? date,
    List<EventParticipant>? participants,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      date: date ?? this.date,
      participants: participants ?? this.participants,
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
          updatedAt == other.updatedAt &&
          date == other.date &&
          listEquals(participants, other.participants);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      location.hashCode ^
      organizerId.hashCode ^
      groupId.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      date.hashCode ^
      Object.hashAll(participants);

  @override
  String toString() {
    return 'Event(id: $id, name: $name, location: $location, organizerId: $organizerId, groupId: $groupId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, date: $date, participants: $participants)';
  }
}
