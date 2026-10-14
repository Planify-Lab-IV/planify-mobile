import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/invitations/domain/invitation_link_parser.dart';

void main() {
  group('InvitationLinkParser', () {
    test(
      'extrae token correctamente de URI válido planify://invite/<token>',
      () {
        final uri = Uri.parse('planify://invite/token-abc-123');
        final token = InvitationLinkParser.parseToken(uri);

        expect(token, equals('token-abc-123'));
      },
    );

    test(
      'soporta mayúsculas en el scheme y en el host de forma insensible',
      () {
        final uri = Uri.parse('PLANIFY://INVITE/token-case-insensitive');
        final token = InvitationLinkParser.parseToken(uri);

        expect(token, equals('token-case-insensitive'));
      },
    );

    test('soporta y limpia trailing slashes en el path', () {
      final uri = Uri.parse('planify://invite/token-slash-end/');
      final token = InvitationLinkParser.parseToken(uri);

      expect(token, equals('token-slash-end'));
    });

    test('retorna null si el esquema no es planify', () {
      final httpUri = Uri.parse('https://planify.app/invite/token-123');
      final customUri = Uri.parse('otherapp://invite/token-123');

      expect(InvitationLinkParser.parseToken(httpUri), isNull);
      expect(InvitationLinkParser.parseToken(customUri), isNull);
    });

    test('retorna null si el host no es invite', () {
      final uri = Uri.parse('planify://events/token-123');
      expect(InvitationLinkParser.parseToken(uri), isNull);
    });

    test('retorna null si no contiene token en el path', () {
      final emptyPathUri = Uri.parse('planify://invite');
      final slashOnlyUri = Uri.parse('planify://invite/');

      expect(InvitationLinkParser.parseToken(emptyPathUri), isNull);
      expect(InvitationLinkParser.parseToken(slashOnlyUri), isNull);
    });

    test('isInvitationLink identifica esquemas y hosts de invitación', () {
      expect(
        InvitationLinkParser.isInvitationLink(
          Uri.parse('planify://invite/tok-1'),
        ),
        isTrue,
      );
      expect(
        InvitationLinkParser.isInvitationLink(Uri.parse('planify://invite')),
        isTrue,
      );
      expect(
        InvitationLinkParser.isInvitationLink(
          Uri.parse('https://planify.app/invite'),
        ),
        isFalse,
      );
      expect(
        InvitationLinkParser.isInvitationLink(
          Uri.parse('planify://other/path'),
        ),
        isFalse,
      );
    });
  });
}
