import '../domain/event.dart';
import '../domain/event_draft.dart';
import '../domain/event_status.dart';
import '../domain/events_repository.dart';
import 'event_exceptions.dart';

class FakeEventsRepository implements EventsRepository {
  final Duration delay;
  final bool shouldThrowError;
  bool shouldFailCancellation;
  int _eventSequence = 1000;
  final Map<String, Event> _events = {};

  FakeEventsRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    this.shouldFailCancellation = false,
    List<Event>? initialEvents,
  }) {
    if (initialEvents != null) {
      for (final event in initialEvents) {
        _events[event.id] = event;
      }
    }
  }

  @override
  Future<Event> createEvent(EventDraft draft, String organizerId) async {
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

    final event = Event(
      id: eventId,
      name: draft.name,
      location: draft.location,
      organizerId: organizerId,
      groupId: groupId,
      status: EventStatus.active,
      createdAt: DateTime.now(),
    );

    _events[eventId] = event;
    return event;
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

    if (shouldFailCancellation) {
      throw const EventCancellationException();
    }

    final event = _events[eventId];
    if (event == null) {
      throw const EventNotFoundException();
    }

    _events[eventId] = event.copyWith(status: EventStatus.cancelled);
  }
}
