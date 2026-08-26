import 'package:flutter_test/flutter_test.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/auth_exceptions.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';

void main() {
  group('FakeAuthRepository', () {
    late FakeAuthRepository repository;
    late FakeSecureStorage storage;

    setUp(() {
      storage = FakeSecureStorage();
      repository = FakeAuthRepository(storage: storage, delay: Duration.zero);
    });

    test(
      'login exitoso con cualquier usuario y contraseña >= 6 caracteres retorna OrganizerSession',
      () async {
        final session = await repository.login(
          identifier: 'lucas@gmail.com',
          password: 'password123',
        );

        expect(session, isA<OrganizerSession>());
        final orgSession = session as OrganizerSession;
        expect(orgSession.email, equals('lucas@gmail.com'));
        expect(orgSession.name, equals('lucas'));
        expect(orgSession.role, equals(UserRole.organizer));
        expect(orgSession.token, isNotEmpty);
        expect(orgSession.isOrganizer, isTrue);

        final current = await repository.getCurrentSession();
        expect(current, equals(session));
      },
    );

    test(
      'loginAnonymously devuelve AnonymousSession con eventId por defecto y sin exponer PIN',
      () async {
        final session = await repository.loginAnonymously(
          name: 'Lucas',
          pin: '1234',
        );

        expect(session, isA<AnonymousSession>());
        final anonSession = session as AnonymousSession;
        expect(anonSession.name, equals('Lucas'));
        expect(anonSession.isAnonymous, isTrue);
        expect(anonSession.role, equals(UserRole.anonymous));
        expect(anonSession.eventId, equals('evt-fake-id'));
        expect(anonSession.token, isNotEmpty);
        expect(anonSession.token.contains('1234'), isFalse);

        final current = await repository.getCurrentSession();
        expect(current, equals(session));
      },
    );

    test(
      'loginAnonymously con eventId personalizado lo asigna correctamente',
      () async {
        final session = await repository.loginAnonymously(
          name: 'Invitado Especial',
          pin: '4321',
          eventId: 'evt-custom-777',
        );

        expect(session, isA<AnonymousSession>());
        final anonSession = session as AnonymousSession;
        expect(anonSession.name, equals('Invitado Especial'));
        expect(anonSession.eventId, equals('evt-custom-777'));
      },
    );

    test(
      'loginAnonymously con PIN menor a 4 caracteres arroja InvalidPinException',
      () async {
        expect(
          () => repository.loginAnonymously(name: 'Lucas', pin: '12'),
          throwsA(isA<InvalidPinException>()),
        );
      },
    );

    test(
      'loginAnonymously con PIN de prueba 9999 arroja InvalidPinException',
      () async {
        expect(
          () => repository.loginAnonymously(name: 'Lucas', pin: '9999'),
          throwsA(isA<InvalidPinException>()),
        );
      },
    );

    test(
      'loginAnonymously con error de red simulado arroja NetworkAuthException',
      () async {
        expect(
          () => repository.loginAnonymously(name: 'Lucas', pin: '0000'),
          throwsA(isA<NetworkAuthException>()),
        );
        expect(
          () => repository.loginAnonymously(name: 'network.error', pin: '1234'),
          throwsA(isA<NetworkAuthException>()),
        );
      },
    );

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

    test(
      'getCurrentSession restaura AnonymousSession desde token almacenado',
      () async {
        await storage.saveToken('fake-guest-token:Lucas:evt-123:999999');

        final session = await repository.getCurrentSession();

        expect(session, isA<AnonymousSession>());
        final anonSession = session as AnonymousSession;
        expect(anonSession.name, equals('Lucas'));
        expect(anonSession.eventId, equals('evt-123'));
        expect(anonSession.isAnonymous, isTrue);
      },
    );
  });
}
