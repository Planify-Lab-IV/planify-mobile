import '../domain/event.dart';
import '../domain/event_draft.dart';
import '../domain/event_status.dart';
import '../domain/events_repository.dart';
import '../domain/attendance_status.dart';
import 'event_exceptions.dart';

class FakeEventsRepository implements EventsRepository {
  final Duration delay;
  final bool shouldThrowError;
  bool shouldFailCancellation;
  bool shouldFailAttendanceResponse;
  int _eventSequence = 1000;
  final Map<String, Event> _events = {};
  final Map<({String eventId, String participantId}), AttendanceStatus>
  _attendance = {};

  FakeEventsRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    this.shouldFailCancellation = false,
    this.shouldFailAttendanceResponse = false,
    List<Event>? initialEvents,
  }) {
    final defaults = [
      Event(
        id: 'evt-123',
        name: 'Cumpleaños de Lucas',
        location: 'Casa de Lucas',
        organizerId: 'org-123',
        groupId: 'grp-amigos',
        status: EventStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
      Event(
        id: 'evt-cumple-lucas',
        name: 'Cumpleaños de Lucas',
        location: 'Casa de Lucas',
        organizerId: 'org-123',
        groupId: 'grp-amigos',
        status: EventStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
      Event(
        id: 'evt-asado-amigos',
        name: 'Asado con Amigos',
        location: 'Club de Campo',
        organizerId: 'org-123',
        groupId: 'grp-amigos',
        status: EventStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
      Event(
        id: 'evt-fake-demo',
        name: 'Evento Demo',
        location: 'Av. Corrientes 1234',
        organizerId: 'org-123',
        groupId: 'grp-amigos',
        status: EventStatus.active,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    final eventsToLoad = initialEvents ?? defaults;
    for (final event in eventsToLoad) {
      _events[event.id] = event;
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

  @override
  Future<AttendanceStatus?> getAttendance(
    String eventId,
    String participantId,
  ) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (!_events.containsKey(eventId)) {
      throw const EventNotFoundException();
    }
    return _attendance[(eventId: eventId, participantId: participantId)];
  }

  @override
  Future<void> confirmAssistance(
    String eventId,
    String participantId,
    String state,
  ) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (shouldFailAttendanceResponse) {
      throw const AttendanceResponseException();
    }
    if (!_events.containsKey(eventId)) {
      throw const EventNotFoundException();
    }

    AttendanceStatus attendanceStatus;
    try {
      attendanceStatus = AttendanceStatus.values.byName(state);
    } on ArgumentError {
      throw const AttendanceResponseException();
    }

    _attendance[(eventId: eventId, participantId: participantId)] =
        attendanceStatus;
  }
}
