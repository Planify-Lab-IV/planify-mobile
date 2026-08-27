import '../domain/event.dart';
import '../domain/event_draft.dart';
import '../domain/events_repository.dart';

class FakeEventsRepository implements EventsRepository {
  final Duration delay;
  final bool shouldThrowError;
  int _eventSequence = 1000;

  FakeEventsRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
  });

  @override
  Future<Event> createEvent(EventDraft draft) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (shouldThrowError) {
      throw Exception('Error al crear el evento');
    }

    _eventSequence++;
    final eventId = 'evt-$_eventSequence';
    final groupId = draft.isNewGroup
        ? 'grp-${DateTime.now().millisecondsSinceEpoch}'
        : (draft.selectedGroupId ?? 'grp-default');
    final groupName = draft.isNewGroup
        ? (draft.newGroupName ?? 'Nuevo Grupo')
        : (draft.selectedGroupName ?? 'Grupo Seleccionado');

    return Event(
      id: eventId,
      name: draft.name,
      location: draft.location,
      groupId: groupId,
      groupName: groupName,
      memberIdentifiers: List.unmodifiable(draft.newGroupMembers),
      createdAt: DateTime.now(),
    );
  }
}
