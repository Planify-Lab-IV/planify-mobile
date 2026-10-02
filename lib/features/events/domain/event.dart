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
  final DateTime? startDateTime;
  final List<EventParticipant> participants;
  final bool expensesClosed;

  const Event({
    required this.id,
    required this.name,
    required this.location,
    required this.organizerId,
    required this.groupId,
    this.status = EventStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.startDateTime,
    this.participants = const [],
    this.expensesClosed = false,
  });

  bool get isCancelled => status.isCancelled;
  bool get isConfirmed => status.isConfirmed;
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
    DateTime? startDateTime,
    List<EventParticipant>? participants,
    bool? expensesClosed,
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
      startDateTime: startDateTime ?? this.startDateTime,
      participants: participants ?? this.participants,
      expensesClosed: expensesClosed ?? this.expensesClosed,
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
          startDateTime == other.startDateTime &&
          listEquals(participants, other.participants) &&
          expensesClosed == other.expensesClosed;

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
      startDateTime.hashCode ^
      Object.hashAll(participants) ^
      expensesClosed.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, name: $name, location: $location, organizerId: $organizerId, groupId: $groupId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, startDateTime: $startDateTime, participants: $participants, expensesClosed: $expensesClosed)';
  }
}
