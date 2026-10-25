import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/notifications/data/fake_notifications_repository.dart';
import 'package:planify/features/notifications/presentation/controllers/push_registration_notifier.dart';

import '../helpers/fake_push_messaging_service.dart';

void main() {
  const organizerState = AuthAuthenticated(
    OrganizerSession(
      userId: 'user-1',
      name: 'Ana',
      email: 'ana@planify.dev',
      username: 'ana',
      token: 'session-token',
    ),
  );
  const anonymousState = AuthAuthenticated(
    AnonymousSession(
      participantId: 'participant-1',
      name: 'Invitado',
      eventId: 'evt-123',
      token: 'anonymous-session-token',
    ),
  );

  group('PushRegistrationNotifier', () {
    late FakeNotificationsRepository repository;
    late FakePushMessagingService pushMessagingService;
    late PushRegistrationNotifier notifier;

    setUp(() {
      repository = FakeNotificationsRepository(delay: Duration.zero);
      pushMessagingService = FakePushMessagingService();
      notifier = PushRegistrationNotifier(
        repository: repository,
        pushMessagingService: pushMessagingService,
      );
    });

    tearDown(() async {
      notifier.dispose();
      await pushMessagingService.dispose();
    });

    test('registra el token al autenticar una sesión de organizador', () async {
      await notifier.handleAuthStateChange(const AuthInitial(), organizerState);

      expect(pushMessagingService.requestPermissionCalls, 1);
      expect(pushMessagingService.getTokenCalls, 1);
      expect(repository.registeredPushTokens, ['fake-push-token']);
    });

    test('no solicita permiso para una sesión anónima', () async {
      await notifier.handleAuthStateChange(const AuthInitial(), anonymousState);

      expect(pushMessagingService.requestPermissionCalls, 0);
      expect(pushMessagingService.getTokenCalls, 0);
      expect(repository.registeredPushTokens, isEmpty);
    });

    test('no registra el dispositivo si el permiso es rechazado', () async {
      pushMessagingService.permissionGranted = false;

      await notifier.handleAuthStateChange(const AuthInitial(), organizerState);

      expect(pushMessagingService.getTokenCalls, 0);
      expect(repository.registeredPushTokens, isEmpty);
    });

    test('ignora un error al registrar para no afectar la sesión', () async {
      repository = FakeNotificationsRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );
      notifier = PushRegistrationNotifier(
        repository: repository,
        pushMessagingService: pushMessagingService,
      );

      await notifier.handleAuthStateChange(const AuthInitial(), organizerState);

      expect(pushMessagingService.requestPermissionCalls, 1);
      expect(repository.registeredPushTokens, isEmpty);
    });

    test('vuelve a registrar el token cuando Firebase lo rota', () async {
      await notifier.handleAuthStateChange(const AuthInitial(), organizerState);
      pushMessagingService.emitTokenRefresh('rotated-push-token');
      await Future<void>.delayed(Duration.zero);

      expect(repository.registeredPushTokens, [
        'fake-push-token',
        'rotated-push-token',
      ]);
    });

    test(
      'deja de registrar tokens al salir de una sesión de organizador',
      () async {
        await notifier.handleAuthStateChange(
          const AuthInitial(),
          organizerState,
        );
        await notifier.handleAuthStateChange(
          organizerState,
          const AuthLoading(),
        );
        pushMessagingService.emitTokenRefresh('rotated-push-token');
        await Future<void>.delayed(Duration.zero);

        expect(repository.registeredPushTokens, ['fake-push-token']);
      },
    );
  });
}
