import 'package:flutter/foundation.dart';

import '../../../events/domain/event_participant.dart';

// Información del detalle de evento que las tareas necesitan para autorizar
// acciones, sin acoplar su provider al provider de otra feature.
class TasksContext {
  final String eventId;
  final String? currentParticipantId;
  final bool isOrganizer;
  final List<EventParticipant> participants;

  TasksContext({
    required this.eventId,
    required this.currentParticipantId,
    required this.isOrganizer,
    required List<EventParticipant> participants,
  }) : participants = List.unmodifiable(participants);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasksContext &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          currentParticipantId == other.currentParticipantId &&
          isOrganizer == other.isOrganizer &&
          listEquals(participants, other.participants);

  @override
  int get hashCode =>
      eventId.hashCode ^
      currentParticipantId.hashCode ^
      isOrganizer.hashCode ^
      Object.hashAll(participants);
}
