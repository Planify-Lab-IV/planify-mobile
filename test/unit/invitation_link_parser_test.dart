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

    test('extrae el token de una URL HTTPS de Web', () {
      final uri = Uri.parse('https://planify.web.app/?invite=token-web-123');

      expect(InvitationLinkParser.parseToken(uri), 'token-web-123');
      expect(InvitationLinkParser.isInvitationLink(uri), isTrue);
    });

    test(
      'rechaza una URL Web sin token o con parámetros invite duplicados',
      () {
        final emptyToken = Uri.parse('https://planify.web.app/?invite=');
        final duplicatedToken = Uri.parse(
          'https://planify.web.app/?invite=one&invite=two',
        );

        expect(InvitationLinkParser.isInvitationLink(emptyToken), isTrue);
        expect(InvitationLinkParser.parseToken(emptyToken), isNull);
        expect(InvitationLinkParser.isInvitationLink(duplicatedToken), isTrue);
        expect(InvitationLinkParser.parseToken(duplicatedToken), isNull);
      },
    );

    test('no trata la página raíz sin invite como un enlace de invitación', () {
      final uri = Uri.parse('https://planify.web.app/');

      expect(InvitationLinkParser.isInvitationLink(uri), isFalse);
      expect(InvitationLinkParser.parseToken(uri), isNull);
    });

    test('decodifica el token Web codificado como query parameter', () {
      final token = 'token+con / caracteres?=&';
      final uri = Uri(
        scheme: 'https',
        host: 'planify.web.app',
        path: '/',
        queryParameters: {'invite': token},
      );

      expect(InvitationLinkParser.parseToken(uri), token);
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

    group('buildShareUrl', () {
      const nativeUrl = 'planify://invite/token-valid-123';
      final webBaseUri = Uri.parse(
        'https://planify.web.app/old-path?old=value',
      );

      test('conserva el deep link original fuera de Web', () {
        expect(
          InvitationLinkParser.buildShareUrl(
            invitationUrl: nativeUrl,
            isWeb: false,
          ),
          nativeUrl,
        );
      });

      test('crea una URL HTTPS de raíz y codifica el token en Web', () {
        const invitationUrl = 'planify://invite/token%2Bcon%2Fslash%3D';

        final shareUrl = InvitationLinkParser.buildShareUrl(
          invitationUrl: invitationUrl,
          isWeb: true,
          webBaseUri: webBaseUri,
        );
        final shareUri = Uri.parse(shareUrl);

        expect(
          shareUri,
          Uri.parse('https://planify.web.app/?invite=token%2Bcon%2Fslash%3D'),
        );
        expect(InvitationLinkParser.parseToken(shareUri), 'token+con/slash=');
      });

      test('rechaza URLs de backend inválidas y orígenes Web no HTTPS', () {
        expect(
          () => InvitationLinkParser.buildShareUrl(
            invitationUrl: 'planify://invite',
            isWeb: true,
            webBaseUri: webBaseUri,
          ),
          throwsFormatException,
        );
        expect(
          () => InvitationLinkParser.buildShareUrl(
            invitationUrl: nativeUrl,
            isWeb: true,
            webBaseUri: Uri.parse('http://localhost:8080/'),
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
