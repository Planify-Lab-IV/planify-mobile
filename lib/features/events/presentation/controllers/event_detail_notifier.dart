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
                status: EventDetailStatus.success,
              )
            : const EventDetailState.initial(),
      ) {
    if (initialEvent == null) {
      loadEvent();
    }
  }

  /// Determina si la sesión actual corresponde al organizador puntual del evento.
  /// Compara el userId de la sesión contra el organizerId del evento puntual.
  /// Nunca se basa únicamente en el rol de la sesión ni en la sola existencia de un organizador.
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
    state = state.copyWith(
      status: EventDetailStatus.loading,
      clearErrorMessage: true,
    );

    try {
      final event = await _repository.getEvent(_eventId);
      if (!mounted) return;

      if (event == null) {
        state = state.copyWith(
          status: EventDetailStatus.error,
          errorMessage: 'Evento no encontrado',
        );
      } else {
        state = state.copyWith(event: event, status: EventDetailStatus.success);
      }
    } on EventsException {
      if (!mounted) return;
      state = state.copyWith(
        status: EventDetailStatus.error,
        errorMessage: 'Error al cargar el evento',
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        status: EventDetailStatus.error,
        errorMessage: 'Error inesperado al cargar el evento',
      );
    }
  }

  Future<bool> cancelEvent() async {
    final currentEvent = state.event;
    if (currentEvent == null) return false;

    if (!isOrganizer) {
      state = state.copyWith(
        errorMessage: 'No tienes permisos para cancelar este evento',
      );
      return false;
    }

    state = state.copyWith(
      isCancelling: true,
      clearErrorMessage: true,
      cancellationSuccess: false,
    );

    try {
      await _repository.cancel(currentEvent.id);
      if (!mounted) return false;

      final updatedEvent = currentEvent.copyWith(status: EventStatus.cancelled);

      state = state.copyWith(
        event: updatedEvent,
        isCancelling: false,
        cancellationSuccess: true,
      );
      return true;
    } on EventsException {
      if (!mounted) return false;
      state = state.copyWith(
        isCancelling: false,
        errorMessage: 'No se pudo cancelar el evento. Intenta nuevamente.',
        cancellationSuccess: false,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isCancelling: false,
        errorMessage: 'No se pudo cancelar el evento. Intenta nuevamente.',
        cancellationSuccess: false,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }
}
