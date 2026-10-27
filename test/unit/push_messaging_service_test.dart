import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/services/push_messaging_service.dart';

import '../helpers/fake_push_messaging_service.dart';

void main() {
  group('PushMessage.fromPayload', () {
    test('conserva el contenido y normaliza el identificador del evento', () {
      final message = PushMessage.fromPayload(
        title: 'Nueva actividad',
        body: 'Ana creó una tarea',
        eventId: ' evt-123 ',
      );

      expect(
        message,
        const PushMessage(
          title: 'Nueva actividad',
          body: 'Ana creó una tarea',
          eventId: 'evt-123',
        ),
      );
    });

    test('descarta payloads sin un identificador de evento válido', () {
      for (final eventId in [null, '', '  ', 123]) {
        expect(
          PushMessage.fromPayload(
            title: 'Nueva actividad',
            body: 'Ana creó una tarea',
            eventId: eventId,
          ),
          isNull,
        );
      }
    });
  });

  group('FakePushMessagingService', () {
    late FakePushMessagingService service;

    setUp(() {
      service = FakePushMessagingService(
        initialMessage: const PushMessage(
          title: 'Evento',
          body: 'Tenés una novedad',
          eventId: 'evt-123',
        ),
      );
    });

    tearDown(() => service.dispose());

    test('expone permiso, token y mensaje inicial configurables', () async {
      service.permissionGranted = false;
      service.token = null;

      expect(await service.requestPermission(), isFalse);
      expect(await service.getToken(), isNull);
      expect((await service.getInitialMessage())?.eventId, 'evt-123');
      expect(service.requestPermissionCalls, 1);
      expect(service.getTokenCalls, 1);
      expect(service.getInitialMessageCalls, 1);
    });

    test(
      'emite las señales de Firebase mediante streams controlables',
      () async {
        final foreground = service.onForegroundMessage.first;
        final opened = service.onMessageOpened.first;
        final refreshedToken = service.onTokenRefresh.first;
        const message = PushMessage(
          title: 'Evento',
          body: 'Tenés una novedad',
          eventId: 'evt-123',
        );

        service.emitForegroundMessage(message);
        service.emitMessageOpened(message);
        service.emitTokenRefresh('rotated-token');

        expect(await foreground, message);
        expect(await opened, message);
        expect(await refreshedToken, 'rotated-token');
      },
    );
  });
}
