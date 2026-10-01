import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/user_session.dart';
import '../../data/event_exceptions.dart';
import '../../domain/event.dart';
import '../../domain/event_status.dart';
import '../../domain/events_repository.dart';
import 'event_detail_state.dart';

class EventDetailNotifier extends StateNotifier<EventDetailState> {
  final EventsRepository _repository;
  final UserSession? _currentSession;
  final String _eventId;

  EventDetailNotifier({
    required EventsRepository repository,
    required UserSession? currentSession,
    required String eventId,
    Event? initialEvent,
  }) : this._(repository, currentSession, eventId, initialEvent);

  EventDetailNotifier._(
    this._repository,
    this._currentSession,
    this._eventId,
    Event? initialEvent,
  ) : super(
        initialEvent != null
            ? EventDetailState(
                event: initialEvent,
                loadStatus: EventDetailLoadStatus.success,
              )
            : const EventDetailState.initial(),
      ) {
    if (initialEvent == null) {
      loadEvent();
    }
  }

  static bool isUserOrganizerOfEvent({
    required UserSession? session,
    required Event? event,
  }) {
    if (session == null || event == null) return false;
    if (session is! OrganizerSession) return false;
    if (session.userId.trim().isEmpty || event.organizerId.trim().isEmpty) {
      return false;
    }
    return session.userId == event.organizerId;
  }

  bool get isOrganizer =>
      isUserOrganizerOfEvent(session: _currentSession, event: state.event);

  bool get hasCurrentSession {
    final session = _currentSession;
    if (session == null) return false;
    return switch (session) {
      OrganizerSession(:final userId) => userId.trim().isNotEmpty,
      AnonymousSession(:final participantId) => participantId.trim().isNotEmpty,
    };
  }

  // Identifica la participación de la sesión actual dentro de este evento
  // Las tareas se asignan a participantes, no a usuarios globales. Una sesión
  // anónima ya recibe ese identificador al ingresar; para una sesión de
  // organizador se busca la participación cuyo `userId` coincide con la suya.
  String? get currentParticipantId {
    final event = state.event;
    final session = _currentSession;
    if (event == null || session == null) return null;

    return switch (session) {
      AnonymousSession(:final participantId, :final eventId)
          when eventId == event.id && participantId.trim().isNotEmpty =>
        participantId,
      OrganizerSession(:final userId) when userId.trim().isNotEmpty =>
        _participantIdForUser(event, userId),
      _ => null,
    };
  }

  String? _participantIdForUser(Event event, String userId) {
    for (final participant in event.participants) {
      if (participant.userId == userId) return participant.id;
    }
    return null;
  }

  bool get canCancelEvent {
    final event = state.event;
    if (event == null) return false;
    return isOrganizer && !event.isCancelled && !state.isCancelling;
  }

  Future<void> loadEvent() async {
    state = state.copyWith(loadStatus: EventDetailLoadStatus.loading);

    try {
      final event = await _repository.getEvent(_eventId);
      if (!mounted) return;

      if (event == null) {
        state = state.copyWith(loadStatus: EventDetailLoadStatus.notFound);
      } else {
        state = state.copyWith(
          event: event,
          loadStatus: EventDetailLoadStatus.success,
        );
      }
    } on EventNotFoundException {
      if (!mounted) return;
      state = state.copyWith(loadStatus: EventDetailLoadStatus.notFound);
    } on EventsException {
      if (!mounted) return;
      state = state.copyWith(loadStatus: EventDetailLoadStatus.error);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadStatus: EventDetailLoadStatus.error);
    }
  }

  Future<bool> cancelEvent() async {
    final currentEvent = state.event;
    if (currentEvent == null) return false;

    if (!isOrganizer) {
      state = state.copyWith(
        cancellationStatus: EventCancellationStatus.failure,
      );
      return false;
    }

    state = state.copyWith(
      cancellationStatus: EventCancellationStatus.inProgress,
    );

    try {
      await _repository.cancel(currentEvent.id);
      if (!mounted) return false;

      final updatedEvent = currentEvent.copyWith(status: EventStatus.cancelled);

      state = state.copyWith(
        event: updatedEvent,
        cancellationStatus: EventCancellationStatus.success,
      );
      return true;
    } on EventsException {
      if (!mounted) return false;
      state = state.copyWith(
        cancellationStatus: EventCancellationStatus.failure,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        cancellationStatus: EventCancellationStatus.failure,
      );
      return false;
    }
  }

  void resetCancellationStatus() {
    state = state.copyWith(cancellationStatus: EventCancellationStatus.idle);
  }
}
