import '../domain/event.dart';
import '../domain/event_draft.dart';
import '../domain/events_repository.dart';
import 'event_exceptions.dart';
import '../domain/event_status.dart';

class FakeEventsRepository implements EventsRepository {
  final Duration delay;
  final bool shouldThrowError;
  int _eventSequence = 1000;
  bool shouldFailCancellation;

  FakeEventsRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    this.shouldFailCancellation = false,
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

    return Event(
      id: eventId,
      name: draft.name,
      location: draft.location,
      groupId: groupId,
      createdAt: DateTime.now(),
    );
  }
  @override
  Future<Event?> getEvent(String eventId) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return _events[eventId];
  }

  @override
  Future<void> cancel(String eventId) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    if (shouldFailCancellation || eventId == errorEventId) {
      throw const EventCancellationException();
    }

    final event = _events[eventId];
    if (event == null) {
      throw const EventNotFoundException();
    }

    _events[eventId] = event.copyWith(status: EventStatus.cancelled);
  }
}
