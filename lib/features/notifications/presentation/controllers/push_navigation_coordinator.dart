import '../../../../core/services/push_messaging_service.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/controllers/auth_state.dart';

/// Decide si una notificación puede abrirse o debe esperar la sesión inicial.
class PushNavigationCoordinator {
  PushNavigationCoordinator({
    required AuthState initialAuthState,
    required this.onNavigate,
  }) : _authState = initialAuthState;

  final void Function(String eventId, String sessionToken) onNavigate;
  AuthState _authState;
  String? _pendingEventId;

  void handleMessage(PushMessage message) {
    final eventId = message.eventId.trim();
    if (eventId.isEmpty) return;

    final auth = _authState;
    if (auth is AuthAuthenticated && auth.session is OrganizerSession) {
      onNavigate(eventId, auth.session.token);
    } else if (auth is AuthInitial || auth is AuthCheckingInitialSession) {
      _pendingEventId = eventId;
    }
  }

  void handleAuthState(AuthState next) {
    _authState = next;
    if (next is AuthInitial || next is AuthCheckingInitialSession) return;

    final eventId = _pendingEventId;
    _pendingEventId = null;
    if (eventId != null &&
        next is AuthAuthenticated &&
        next.session is OrganizerSession) {
      onNavigate(eventId, next.session.token);
    }
  }
}
