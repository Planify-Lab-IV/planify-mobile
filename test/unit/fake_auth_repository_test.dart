import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/auth/data/auth_exceptions.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';

void main() {
  group('FakeAuthRepository', () {
    late FakeAuthRepository repository;

    setUp(() {
      repository = FakeAuthRepository(delay: Duration.zero);
    });

    test(
      'login exitoso con cualquier usuario y contraseña >= 6 caracteres',
      () async {
        final session = await repository.login(
          identifier: 'lucas@gmail.com',
          password: 'password123',
        );

        expect(session.email, equals('lucas@gmail.com'));
        expect(session.name, equals('lucas'));
        expect(session.role, equals(UserRole.organizer));
        expect(session.token, isNotEmpty);
        expect(session.isOrganizer, isTrue);

        final current = await repository.getCurrentSession();
        expect(current, equals(session));
      },
    );

    test('loginAnonymously devuelve sesión con rol anonymous', () async {
      final session = await repository.loginAnonymously();

      expect(session.isAnonymous, isTrue);
      expect(session.role, equals(UserRole.anonymous));
      expect(session.token, isNotEmpty);

      final current = await repository.getCurrentSession();
      expect(current, equals(session));
    });

    test(
      'login con contraseña menor a 6 caracteres arroja InvalidCredentialsException',
      () async {
        expect(
          () => repository.login(
            identifier: 'usuario@gmail.com',
            password: '123',
          ),
          throwsA(isA<InvalidCredentialsException>()),
        );
      },
    );

    test('login con error de red arroja NetworkAuthException', () async {
      expect(
        () => repository.login(
          identifier: 'network.error@planify.com',
          password: 'password123',
        ),
        throwsA(isA<NetworkAuthException>()),
      );
    });

    test('logout limpia la sesión actual', () async {
      await repository.login(
        identifier: 'lucas@gmail.com',
        password: 'password123',
      );

      await repository.logout();

      final current = await repository.getCurrentSession();
      expect(current, isNull);
    });
  });
}
