import '../domain/event.dart';
import '../domain/event_draft.dart';
import '../domain/event_participant.dart';
import '../domain/event_status.dart';
import '../domain/events_repository.dart';
import '../domain/attendance_status.dart';
import 'event_exceptions.dart';

class FakeEventsRepository implements EventsRepository {
  static const defaultOrganizerId = 'org-123';

  final Duration delay;
  final bool shouldThrowError;
  final String _organizerId;
  bool shouldFailCancellation;
  bool shouldFailAttendanceResponse;
  bool shouldFailScheduleConfirmation;
  int _eventSequence = 1000;
  final Map<String, Event> _events = {};
  // cada entry representa el attendance status del current user para un eventid
  final Map<String, AttendanceStatus> _currentUserAttendance = {};

  FakeEventsRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    String organizerId = defaultOrganizerId,
    this.shouldFailCancellation = false,
    this.shouldFailAttendanceResponse = false,
    this.shouldFailScheduleConfirmation = false,
    List<Event>? initialEvents,
  }) : _organizerId = organizerId.trim().isEmpty
           ? defaultOrganizerId
           : organizerId.trim() {
    final defaults = [
      Event(
        id: 'evt-123',
        name: 'Cumpleaños de Lucas',
        location: 'Casa de Lucas',
        organizerId: _organizerId,
        groupId: 'grp-amigos',
        status: EventStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        participants: _defaultParticipants('evt-123', _organizerId),
      ),
      Event(
        id: 'evt-cumple-lucas',
        name: 'Cumpleaños de Lucas',
        location: 'Casa de Lucas',
        organizerId: _organizerId,
        groupId: 'grp-amigos',
        status: EventStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        participants: _defaultParticipants('evt-cumple-lucas', _organizerId),
      ),
      Event(
        id: 'evt-asado-amigos',
        name: 'Asado con Amigos',
        location: 'Club de Campo',
        organizerId: _organizerId,
        groupId: 'grp-amigos',
        status: EventStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        participants: _defaultParticipants('evt-asado-amigos', _organizerId),
      ),
      Event(
        id: 'evt-fake-demo',
        name: 'Evento Demo',
        location: 'Av. Corrientes 1234',
        organizerId: _organizerId,
        groupId: 'grp-amigos',
        status: EventStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        participants: _defaultParticipants('evt-fake-demo', _organizerId),
      ),
    ];

    final eventsToLoad = initialEvents ?? defaults;
    for (final event in eventsToLoad) {
      _events[event.id] = event;
    }
  }

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
    final now = DateTime.now();
    final groupId = draft.isNewGroup
        ? 'grp-${DateTime.now().millisecondsSinceEpoch}'
        : (draft.selectedGroupId ?? 'grp-default');

    final event = Event(
      id: eventId,
      name: draft.name,
      location: draft.location,
      organizerId: _organizerId,
      groupId: groupId,
      status: EventStatus.active,
      createdAt: now,
      updatedAt: now,
      participants: _defaultParticipants(eventId, _organizerId),
    );

    _events[eventId] = event;
    return event;
  }

  @override
  Future<Event?> getEvent(String eventId) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (shouldThrowError) {
      throw const NetworkEventException();
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
  Future<void> confirmSchedule(String eventId, DateTime startDateTime) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (shouldFailScheduleConfirmation) {
      throw const EventScheduleConfirmationException();
    }
    if (startDateTime.isBefore(DateTime.now())) {
      throw const EventScheduleValidationException();
    }

    final event = _events[eventId];
    if (event == null) {
      throw const EventNotFoundException();
    }
    if (event.isCancelled) {
      throw const EventScheduleValidationException();
    }

    _events[eventId] = event.copyWith(
      status: EventStatus.confirmed,
      startDateTime: startDateTime,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<AttendanceStatus> getCurrentUserAttendance(String eventId) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (!_events.containsKey(eventId)) {
      throw const EventNotFoundException();
    }
    return _currentUserAttendance[eventId] ?? AttendanceStatus.noResponse;
  }

  @override
  Future<void> updateCurrentUserAttendance(
    String eventId,
    AttendanceResponse response,
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

    _currentUserAttendance[eventId] = response.status;
  }

  static List<EventParticipant> _defaultParticipants(
    String eventId,
    String organizerId,
  ) {
    return [
      EventParticipant(
        id: 'participant-org-$eventId',
        eventId: eventId,
        userId: organizerId,
        username: 'Lucía',
        isAnonymous: false,
        isOrganizer: true,
      ),
      EventParticipant(
        id: 'participant-member-$eventId',
        eventId: eventId,
        userId: 'user-456',
        username: 'Ana',
        isAnonymous: false,
        isOrganizer: false,
      ),
      EventParticipant(
        id: 'participant-anon-$eventId',
        eventId: eventId,
        userId: null,
        username: 'Juan',
        isAnonymous: true,
        isOrganizer: false,
      ),
    ];
  }
}
