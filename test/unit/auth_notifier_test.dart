import 'package:flutter_test/flutter_test.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';

void main() {
  group('AuthNotifier', () {
    late FakeAuthRepository repository;
    late FakeSecureStorage storage;
    late AuthNotifier notifier;

    setUp(() {
      repository = FakeAuthRepository(delay: Duration.zero);
      storage = FakeSecureStorage();
      notifier = AuthNotifier(repository, storage);
    });

    test('estado inicial es AuthInitial', () {
      expect(notifier.state, isA<AuthInitial>());
    });

    test('login exitoso guarda token y cambia a AuthAuthenticated', () async {
      await notifier.login(
        identifier: 'organizador@planify.com',
        password: 'password123',
      );

      expect(notifier.state, isA<AuthAuthenticated>());
      final authState = notifier.state as AuthAuthenticated;
      expect(authState.session.email, equals('organizador@planify.com'));

      final storedToken = await storage.getToken();
      expect(storedToken, equals(authState.session.token));
    });

    test('login fallido cambia a AuthError con motivo y no guarda token', () async {
      await notifier.login(
        identifier: 'invalido@externo.com',
        password: '123',
      );

      expect(notifier.state, isA<AuthError>());
      final errorState = notifier.state as AuthError;
      expect(errorState.reason, equals(AuthFailureReason.invalidCredentials));

      final storedToken = await storage.getToken();
      expect(storedToken, isNull);
    });

    test('logout elimina token y cambia a AuthUnauthenticated', () async {
      await notifier.login(
        identifier: 'organizador@planify.com',
        password: 'password123',
      );

      await notifier.logout();

      expect(notifier.state, isA<AuthUnauthenticated>());
      final storedToken = await storage.getToken();
      expect(storedToken, isNull);
    });
  });
}
