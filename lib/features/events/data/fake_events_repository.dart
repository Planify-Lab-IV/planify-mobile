import '../domain/event.dart';
import '../domain/event_status.dart';
import '../domain/events_repository.dart';
import 'event_exceptions.dart';

class FakeEventsRepository implements EventsRepository {
  final Duration delay;
  final Map<String, Event> _events = {};
  bool shouldFailCancellation;

  static const String defaultEventId = 'evt-test-123';
  static const String defaultOrganizerId = 'org-123';
  static const String errorEventId = 'evt-error-123';

  FakeEventsRepository({
    this.delay = const Duration(milliseconds: 500),
    this.shouldFailCancellation = false,
    List<Event>? initialEvents,
  }) {
    if (initialEvents != null) {
      for (final event in initialEvents) {
        _events[event.id] = event;
      }
    } else {
      _events[defaultEventId] = const Event(
        id: defaultEventId,
        name: 'Cumpleaños de Lucas',
        location: 'Av. Corrientes 1234',
        organizerId: defaultOrganizerId,
        status: EventStatus.active,
      );
      _events[errorEventId] = const Event(
        id: errorEventId,
        name: 'Evento con Error',
        location: 'Calle Falsa 123',
        organizerId: defaultOrganizerId,
        status: EventStatus.active,
      );
    }
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
