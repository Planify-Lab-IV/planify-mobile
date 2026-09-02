import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/invitations/data/fake_invitations_repository.dart';
import 'package:planify/features/invitations/data/invitation_exceptions.dart';

void main() {
  group('FakeInvitationsRepository', () {
    late FakeInvitationsRepository repository;

    setUp(() {
      repository = FakeInvitationsRepository(delay: Duration.zero);
    });

    test('token-valid-123 resuelve correctamente al eventId evt-123', () async {
      final eventId = await repository.resolveInvitationToken(
        'token-valid-123',
      );
      expect(eventId, equals('evt-123'));
    });

    test('valid-token resuelve correctamente al eventId evt-123', () async {
      final eventId = await repository.resolveInvitationToken('valid-token');
      expect(eventId, equals('evt-123'));
    });

    test(
      'token-cumple-lucas resuelve correctamente al eventId evt-cumple-lucas',
      () async {
        final eventId = await repository.resolveInvitationToken(
          'token-cumple-lucas',
        );
        expect(eventId, equals('evt-cumple-lucas'));
      },
    );

    test(
      'token con prefijo valid- resuelve dinámicamente el eventId correspondiente',
      () async {
        final eventId = await repository.resolveInvitationToken(
          'valid-asado-amigos',
        );
        expect(eventId, equals('evt-asado-amigos'));
      },
    );

    test(
      'token vacío o con espacios arroja InvalidInvitationException',
      () async {
        expect(
          () => repository.resolveInvitationToken(''),
          throwsA(isA<InvalidInvitationException>()),
        );
        expect(
          () => repository.resolveInvitationToken('   '),
          throwsA(isA<InvalidInvitationException>()),
        );
      },
    );

    test(
      'token marcado como inválido arroja InvalidInvitationException',
      () async {
        expect(
          () => repository.resolveInvitationToken('token-invalid'),
          throwsA(isA<InvalidInvitationException>()),
        );
        expect(
          () => repository.resolveInvitationToken('invalid-token'),
          throwsA(isA<InvalidInvitationException>()),
        );
      },
    );

    test('token expirado arroja InvitationExpiredException', () async {
      expect(
        () => repository.resolveInvitationToken('token-expired'),
        throwsA(isA<InvitationExpiredException>()),
      );
      expect(
        () => repository.resolveInvitationToken('expired-token'),
        throwsA(isA<InvitationExpiredException>()),
      );
    });

    test(
      'token con error de red simulado arroja NetworkInvitationException',
      () async {
        expect(
          () => repository.resolveInvitationToken('token-network-error'),
          throwsA(isA<NetworkInvitationException>()),
        );
        expect(
          () => repository.resolveInvitationToken('network-error'),
          throwsA(isA<NetworkInvitationException>()),
        );
      },
    );

    test('token no registrado arroja InvitationNotFoundException', () async {
      expect(
        () => repository.resolveInvitationToken('token-desconocido-999'),
        throwsA(isA<InvitationNotFoundException>()),
      );
    });

    test(
      'el token confidencial no es retornado de forma idéntica como eventId',
      () async {
        const token = 'token-valid-123';
        final eventId = await repository.resolveInvitationToken(token);
        expect(eventId, isNot(equals(token)));
      },
    );
  });
}
