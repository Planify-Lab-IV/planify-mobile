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
    if (session.userId.trim().isEmpty || event.organizerId.trim().isEmpty) {
      return false;
    }
    return session.userId == event.organizerId;
  }

  bool get isOrganizer =>
      isUserOrganizerOfEvent(session: _currentSession, event: state.event);

  bool get canCancelEvent {
    final event = state.event;
    if (event == null) return false;
    return isOrganizer && event.isActive && !state.isCancelling;
  }

  Future<void> loadEvent() async {
    state = state.copyWith(loadStatus: EventDetailLoadStatus.loading);

    try {
      final event = await _repository.getEvent(_eventId);
      if (!mounted) return;

      if (event == null) {
        state = state.copyWith(loadStatus: EventDetailLoadStatus.error);
      } else {
        state = state.copyWith(
          event: event,
          loadStatus: EventDetailLoadStatus.success,
        );
      }
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
