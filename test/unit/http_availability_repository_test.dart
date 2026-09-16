import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/availability/data/availability_exceptions.dart';
import 'package:planify/features/availability/data/http_availability_repository.dart';
import 'package:planify/features/availability/domain/slot.dart';

void main() {
  Dio dioResolving(
    dynamic body,
    void Function(RequestOptions options)? inspect,
  ) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          inspect?.call(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: body,
            ),
          );
        },
      ),
    );
    return dio;
  }

  group('HttpAvailabilityRepository', () {
    test('loads slots using the backend availability contract', () async {
      RequestOptions? request;
      final repository = HttpAvailabilityRepository(
        dio: dioResolving(
          {
            'slots': [
              {'weekDay': 0, 'hourBlock': 9},
              {'weekDay': 5, 'hourBlock': 18},
            ],
          },
          (options) => request = options,
        ),
      );

      final slots = await repository.load('evt-1');

      expect(request?.method, 'GET');
      expect(request?.path, '/events/evt-1/availability');
      expect(
        slots,
        [Slot(weekDay: 0, hourBlock: 9), Slot(weekDay: 5, hourBlock: 18)],
      );
    });

    test('saves the complete slot selection using backend field names', () async {
      RequestOptions? request;
      final repository = HttpAvailabilityRepository(
        dio: dioResolving(null, (options) => request = options),
      );

      await repository.save('evt-1', [
        Slot(weekDay: 1, hourBlock: 8),
        Slot(weekDay: 4, hourBlock: 21),
      ]);

      expect(request?.method, 'PUT');
      expect(request?.path, '/events/evt-1/availability');
      expect(request?.data, {
        'slots': [
          {'weekDay': 1, 'hourBlock': 8},
          {'weekDay': 4, 'hourBlock': 21},
        ],
      });
    });

    test('rejects a malformed load response', () async {
      final repository = HttpAvailabilityRepository(
        dio: dioResolving({'slots': [{'weekDay': 1}]}, null),
      );

      expect(
        () => repository.load('evt-1'),
        throwsA(isA<InvalidAvailabilityResponseException>()),
      );
    });

    test('maps connection failures to a network exception', () async {
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
      final repository = HttpAvailabilityRepository(dio: dio);

      expect(
        () => repository.save('evt-1', const []),
        throwsA(isA<NetworkAvailabilityException>()),
      );
    });
  });
}
