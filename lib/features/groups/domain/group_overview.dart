import 'package:flutter/foundation.dart';

import '../../events/domain/event_status.dart';

class GroupOverview {
  final String id;
  final String name;
  final int memberCount;
  final List<GroupEventSummary> events;

  GroupOverview({
    required this.id,
    required this.name,
    required this.memberCount,
    required List<GroupEventSummary> events,
  }) : events = List.unmodifiable(events);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupOverview &&
          id == other.id &&
          name == other.name &&
          memberCount == other.memberCount &&
          listEquals(events, other.events);

  @override
  int get hashCode =>
      Object.hash(id, name, memberCount, Object.hashAll(events));
}

class GroupEventSummary {
  final String id;
  final String name;
  final EventStatus status;
  final DateTime? startDateTime;
  final String location;

  const GroupEventSummary({
    required this.id,
    required this.name,
    required this.status,
    this.startDateTime,
    required this.location,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupEventSummary &&
          id == other.id &&
          name == other.name &&
          status == other.status &&
          startDateTime == other.startDateTime &&
          location == other.location;

  @override
  int get hashCode => Object.hash(id, name, status, startDateTime, location);
}
