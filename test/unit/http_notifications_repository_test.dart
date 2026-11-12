import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/notifications/data/http_notifications_repository.dart';
import 'package:planify/features/notifications/data/notification_exceptions.dart';
import 'package:planify/data/dio_client.dart';
import 'package:planify/data/secure_storage.dart';

void main() {
  Dio dioResolving(void Function(RequestOptions options)? inspect) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          inspect?.call(options);
          handler.resolve(
            Response<dynamic>(requestOptions: options, statusCode: 204),
          );
        },
      ),
    );
    return dio;
  }

  Dio dioRejecting(int statusCode) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: statusCode,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ),
    );
    return dio;
  }

  Dio dioWithNetworkError() {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      ),
    );
    return dio;
  }

  group('HttpNotificationsRepository.registerDevice', () {
    test('posts the normalized token to the register endpoint', () async {
      RequestOptions? request;
      final repository = HttpNotificationsRepository(
        dio: dioResolving((options) => request = options),
      );

      await repository.registerDevice('  push-token  ');

      expect(request?.method, 'POST');
      expect(request?.path, '/notifications/register-device');
      expect(request?.data, {'pushToken': 'push-token'});
    });

    test('rejects a blank token before sending a request', () async {
      var requestCount = 0;
      final repository = HttpNotificationsRepository(
        dio: dioResolving((_) => requestCount++),
      );

      await expectLater(
        repository.registerDevice('  '),
        throwsA(isA<NotificationValidationException>()),
      );
      expect(requestCount, 0);
    });
  });

  group('HttpNotificationsRepository.unregisterDevice', () {
    test(
      'conserva las credenciales de la sesión que originó la operación',
      () async {
        final storage = FakeSecureStorage();
        await storage.saveToken('session-b');
        final dio = DioClient.create(storage: storage);
        RequestOptions? request;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              request = options;
              handler.resolve(
                Response<dynamic>(requestOptions: options, statusCode: 204),
              );
            },
          ),
        );
        final repository = HttpNotificationsRepository(dio: dio);
        await repository.unregisterDevice(
          'push-token',
          sessionToken: 'session-a',
        );
        expect(request?.headers['Authorization'], 'Bearer session-a');
      },
    );

    test('posts the normalized token to the unregister endpoint', () async {
      RequestOptions? request;
      final repository = HttpNotificationsRepository(
        dio: dioResolving((options) => request = options),
      );

      await repository.unregisterDevice('  push-token  ');

      expect(request?.method, 'POST');
      expect(request?.path, '/notifications/unregister-device');
      expect(request?.data, {'pushToken': 'push-token'});
    });
  });

  group('HttpNotificationsRepository HTTP errors', () {
    test('maps 400 to NotificationValidationException', () async {
      final repository = HttpNotificationsRepository(dio: dioRejecting(400));

      await expectLater(
        repository.registerDevice('push-token'),
        throwsA(isA<NotificationValidationException>()),
      );
    });

    test('maps 401 and 403 to NotificationAuthorizationException', () async {
      for (final statusCode in [401, 403]) {
        final repository = HttpNotificationsRepository(
          dio: dioRejecting(statusCode),
        );

        await expectLater(
          repository.unregisterDevice('push-token'),
          throwsA(isA<NotificationAuthorizationException>()),
        );
      }
    });

    test('maps network failures to NetworkNotificationException', () async {
      final repository = HttpNotificationsRepository(
        dio: dioWithNetworkError(),
      );

      await expectLater(
        repository.registerDevice('push-token'),
        throwsA(isA<NetworkNotificationException>()),
      );
    });

    test(
      'maps unexpected HTTP failures to NotificationOperationException',
      () async {
        final repository = HttpNotificationsRepository(dio: dioRejecting(500));

        await expectLater(
          repository.registerDevice('push-token'),
          throwsA(isA<NotificationOperationException>()),
        );
      },
    );
  });
}
