import 'package:flutter/foundation.dart';

import '../../../events/domain/event_participant.dart';

class AddExpenseContext {
  final String eventId;
  final List<EventParticipant> participants;

  AddExpenseContext({
    required this.eventId,
    required List<EventParticipant> participants,
  }) : participants = List.unmodifiable(participants);

  @override
  bool operator ==(Object other) =>
      other is AddExpenseContext &&
      eventId == other.eventId &&
      listEquals(participants, other.participants);

  @override
  int get hashCode => Object.hash(eventId, Object.hashAll(participants));
}
