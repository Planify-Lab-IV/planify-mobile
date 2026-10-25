import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/services/push_messaging_service.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/notifications/presentation/controllers/push_navigation_coordinator.dart';

const organizer = OrganizerSession(
  userId: 'user-1',
  email: 'user@example.com',
  name: 'Usuario',
  username: 'usuario',
  token: 'session-token',
);
const anonymous = AnonymousSession(
  participantId: 'guest-1',
  name: 'Invitado',
  eventId: 'event-1',
  token: 'guest-token',
);
const message = PushMessage(
  title: 'Título',
  body: 'Cuerpo',
  eventId: 'event-1',
);

void main() {
  late List<(String, String)> navigations;

  PushNavigationCoordinator createCoordinator(AuthState auth) {
    return PushNavigationCoordinator(
      initialAuthState: auth,
      onNavigate: (eventId, token) => navigations.add((eventId, token)),
    );
  }

  setUp(() => navigations = []);

  test('abre el evento cuando ya hay una sesión de organizador', () {
    final coordinator = createCoordinator(const AuthAuthenticated(organizer));
    coordinator.handleMessage(message);
    expect(navigations, [('event-1', 'session-token')]);
  });

  test(
    'espera la restauración de la sesión y consume el pendiente una vez',
    () {
      final coordinator = createCoordinator(const AuthCheckingInitialSession());
      coordinator.handleMessage(message);
      expect(navigations, isEmpty);

      coordinator.handleAuthState(const AuthAuthenticated(organizer));
      coordinator.handleAuthState(const AuthAuthenticated(organizer));
      expect(navigations, [('event-1', 'session-token')]);
    },
  );

  test(
    'descarta el pendiente sin sesión y no lo abre en un login posterior',
    () {
      final coordinator = createCoordinator(const AuthInitial());
      coordinator.handleMessage(message);
      coordinator.handleAuthState(const AuthUnauthenticated());
      coordinator.handleAuthState(const AuthAuthenticated(organizer));
      expect(navigations, isEmpty);
    },
  );

  test('no abre notificaciones para participantes anónimos', () {
    final coordinator = createCoordinator(const AuthCheckingInitialSession());
    coordinator.handleMessage(message);
    coordinator.handleAuthState(const AuthAuthenticated(anonymous));
    coordinator.handleMessage(message);
    coordinator.handleAuthState(const AuthAuthenticated(organizer));
    expect(navigations, isEmpty);
  });

  test('conserva el último evento recibido durante el arranque', () {
    final coordinator = createCoordinator(const AuthCheckingInitialSession());
    coordinator.handleMessage(message);
    coordinator.handleMessage(
      const PushMessage(title: '', body: '', eventId: 'event-2'),
    );
    coordinator.handleAuthState(const AuthAuthenticated(organizer));
    expect(navigations, [('event-2', 'session-token')]);
  });

  test(
    'descarta el pendiente si falla la restauración o comienza otra acción',
    () {
      for (final next in [
        const AuthError(AuthFailureReason.networkError),
        const AuthLoading(),
      ]) {
        final coordinator = createCoordinator(
          const AuthCheckingInitialSession(),
        );
        coordinator.handleMessage(message);
        coordinator.handleAuthState(next);
        coordinator.handleAuthState(const AuthAuthenticated(organizer));
      }
      expect(navigations, isEmpty);
    },
  );

  test('ignora un identificador de evento vacío', () {
    final coordinator = createCoordinator(const AuthAuthenticated(organizer));
    coordinator.handleMessage(
      const PushMessage(title: '', body: '', eventId: '  '),
    );
    expect(navigations, isEmpty);
  });
}
