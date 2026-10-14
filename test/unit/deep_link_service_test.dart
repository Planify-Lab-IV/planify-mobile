import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/services/deep_link_service.dart';

class FakeAppLinks implements AppLinks {
  Uri? initialUri;
  final StreamController<Uri> _uriController =
      StreamController<Uri>.broadcast();

  void emitUri(Uri uri) {
    _uriController.add(uri);
  }

  void emitError(Object error) {
    _uriController.addError(error);
  }

  @override
  Stream<Uri> get uriLinkStream => _uriController.stream;

  @override
  Stream<String> get stringLinkStream =>
      _uriController.stream.map((u) => u.toString());

  @override
  Future<Uri?> getInitialLink() async => initialUri;

  @override
  Future<String?> getInitialLinkString() async => initialUri?.toString();

  @override
  Future<Uri?> getLatestLink() async => initialUri;

  @override
  Future<String?> getLatestLinkString() async => initialUri?.toString();
}

void main() {
  group('DeepLinkService', () {
    late FakeAppLinks fakeAppLinks;
    late DeepLinkService deepLinkService;

    setUp(() {
      fakeAppLinks = FakeAppLinks();
      deepLinkService = DeepLinkService(appLinks: fakeAppLinks);
    });

    tearDown(() {
      deepLinkService.dispose();
    });

    test(
      'despacha el initialLink al iniciar la escucha si la app abrió con link (cold start)',
      () async {
        final expectedUri = Uri.parse('planify://invite/token-cold-start');
        fakeAppLinks.initialUri = expectedUri;

        final receivedUris = <Uri>[];
        await deepLinkService.listen((uri) {
          receivedUris.add(uri);
        });

        expect(receivedUris, hasLength(1));
        expect(receivedUris.first, equals(expectedUri));
      },
    );

    test(
      'despacha links entrantes desde el stream mientras la app está corriendo',
      () async {
        final receivedUris = <Uri>[];
        await deepLinkService.listen((uri) {
          receivedUris.add(uri);
        });

        final incomingUri1 = Uri.parse('planify://invite/token-runtime-1');
        final incomingUri2 = Uri.parse('planify://invite/token-runtime-2');

        fakeAppLinks.emitUri(incomingUri1);
        fakeAppLinks.emitUri(incomingUri2);

        await pumpEventQueue();

        expect(receivedUris, equals([incomingUri1, incomingUri2]));
      },
    );

    test(
      'maneja errores de stream sin romper la suscripción ni lanzar excepciones no controladas',
      () async {
        final receivedUris = <Uri>[];
        await deepLinkService.listen((uri) {
          receivedUris.add(uri);
        });

        fakeAppLinks.emitError(Exception('Stream error simulado'));

        final validUri = Uri.parse('planify://invite/token-after-error');
        fakeAppLinks.emitUri(validUri);

        await pumpEventQueue();

        expect(receivedUris, equals([validUri]));
      },
    );

    test('dispose cancela la suscripción activa', () async {
      final receivedUris = <Uri>[];
      await deepLinkService.listen((uri) {
        receivedUris.add(uri);
      });

      deepLinkService.dispose();

      fakeAppLinks.emitUri(Uri.parse('planify://invite/token-ignored'));
      await pumpEventQueue();

      expect(receivedUris, isEmpty);
    });
  });
}
