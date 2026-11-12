import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/services/web_invitation_url_cleaner.dart';

void main() {
  group('WebInvitationUrlCleaner', () {
    test('elimina invite y conserva los otros query parameters', () {
      Uri? replacedUri;
      final cleaner = WebInvitationUrlCleaner(
        isWeb: true,
        uriProvider: () => Uri.parse(
          'https://planify.web.app/?invite=token-secret&utm_source=email',
        ),
        replaceUrl: (uri) => replacedUri = uri,
      );

      cleaner.clearInviteQuery();

      expect(
        replacedUri,
        Uri.parse('https://planify.web.app/?utm_source=email'),
      );
    });

    test('elimina por completo una query que solo contiene invite', () {
      Uri? replacedUri;
      final cleaner = WebInvitationUrlCleaner(
        isWeb: true,
        uriProvider: () => Uri.parse('https://planify.web.app/?invite=token'),
        replaceUrl: (uri) => replacedUri = uri,
      );

      cleaner.clearInviteQuery();

      expect(replacedUri, Uri.parse('https://planify.web.app/'));
    });

    test('no reemplaza la URL sin invite o fuera de Web', () {
      var replacements = 0;
      final withoutInvite = WebInvitationUrlCleaner(
        isWeb: true,
        uriProvider: () =>
            Uri.parse('https://planify.web.app/?utm_source=email'),
        replaceUrl: (_) => replacements++,
      );
      final native = WebInvitationUrlCleaner(
        isWeb: false,
        uriProvider: () => Uri.parse('https://planify.web.app/?invite=token'),
        replaceUrl: (_) => replacements++,
      );

      withoutInvite.clearInviteQuery();
      native.clearInviteQuery();

      expect(replacements, 0);
    });
  });
}
