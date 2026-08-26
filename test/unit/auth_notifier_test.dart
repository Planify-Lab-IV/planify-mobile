import 'package:flutter_test/flutter_test.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';

void main() {
  group('AuthNotifier', () {
    late FakeAuthRepository repository;
    late FakeSecureStorage storage;
    late AuthNotifier notifier;

    setUp(() {
      storage = FakeSecureStorage();
      repository = FakeAuthRepository(storage: storage, delay: Duration.zero);
      notifier = AuthNotifier(repository, storage);
    });

    test('estado inicial es AuthInitial', () {
      expect(notifier.state, isA<AuthInitial>());
    });

    test(
      'login exitoso guarda token y cambia a AuthAuthenticated con OrganizerSession',
      () async {
        await notifier.login(
          identifier: 'lucas@gmail.com',
          password: 'password123',
        );

        expect(notifier.state, isA<AuthAuthenticated>());
        final authState = notifier.state as AuthAuthenticated;
        expect(authState.session, isA<OrganizerSession>());
        final orgSession = authState.session as OrganizerSession;
        expect(orgSession.email, equals('lucas@gmail.com'));
        expect(orgSession.isOrganizer, isTrue);

        final storedToken = await storage.getToken();
        expect(storedToken, equals(orgSession.token));
      },
    );

    test(
      'loginAnonymously guarda token y cambia a AuthAuthenticated con AnonymousSession',
      () async {
        await notifier.loginAnonymously(name: 'Lucas', pin: '1234');

        expect(notifier.state, isA<AuthAuthenticated>());
        final authState = notifier.state as AuthAuthenticated;
        expect(authState.session, isA<AnonymousSession>());
        final anonSession = authState.session as AnonymousSession;
        expect(anonSession.name, equals('Lucas'));
        expect(anonSession.isAnonymous, isTrue);
        expect(anonSession.eventId, equals('evt-fake-id'));

        final storedToken = await storage.getToken();
        expect(storedToken, equals(anonSession.token));
        expect(storedToken!.contains('1234'), isFalse);
      },
    );

    test(
      'loginAnonymously con PIN inválido cambia a AuthError(invalidPin) y no guarda token',
      () async {
        await notifier.loginAnonymously(name: 'Lucas', pin: '9999');

        expect(notifier.state, isA<AuthError>());
        final errorState = notifier.state as AuthError;
        expect(errorState.reason, equals(AuthFailureReason.invalidPin));

        final storedToken = await storage.getToken();
        expect(storedToken, isNull);
      },
    );

    test(
      'login fallido cambia a AuthError con motivo y no guarda token',
      () async {
        await notifier.login(
          identifier: 'invalido@externo.com',
          password: '123',
        );

        expect(notifier.state, isA<AuthError>());
        final errorState = notifier.state as AuthError;
        expect(errorState.reason, equals(AuthFailureReason.invalidCredentials));

        final storedToken = await storage.getToken();
        expect(storedToken, isNull);
      },
    );

    test('logout elimina token y cambia a AuthUnauthenticated', () async {
      await notifier.login(
        identifier: 'lucas@gmail.com',
        password: 'password123',
      );

      await notifier.logout();

      expect(notifier.state, isA<AuthUnauthenticated>());
      final storedToken = await storage.getToken();
      expect(storedToken, isNull);
    });

    test('checkAuthStatus restaura sesion si hay token guardado', () async {
      await storage.saveToken('fake-org-token:lucas@gmail.com:123456');

      await notifier.checkAuthStatus();

      expect(notifier.state, isA<AuthAuthenticated>());
      final authState = notifier.state as AuthAuthenticated;
      expect(authState.session, isA<OrganizerSession>());
      final orgSession = authState.session as OrganizerSession;
      expect(orgSession.email, equals('lucas@gmail.com'));
      expect(orgSession.name, equals('lucas'));
    });
  });
}
