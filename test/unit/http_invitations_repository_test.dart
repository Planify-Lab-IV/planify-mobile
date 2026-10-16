import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/invitations/data/http_invitations_repository.dart';
import 'package:planify/features/invitations/data/invitation_exceptions.dart';

void main() {
  group('HttpInvitationsRepository', () {
    const validToken = 'valid-token-123456789012345678901234567890';
    const expectedEventId = 'evt-1234-uuid';

    Dio dioResolving(
      dynamic body,
      void Function(RequestOptions)? inspect, {
      int statusCode = 200,
    }) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            inspect?.call(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: statusCode,
                data: body,
              ),
            );
          },
        ),
      );
      return dio;
    }

    Dio dioRejecting(
      int statusCode,
      dynamic body, {
      void Function(RequestOptions)? inspect,
    }) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            inspect?.call(options);
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: statusCode,
                  data: body,
                ),
              ),
            );
          },
        ),
      );
      return dio;
    }

    test('resolves token and returns eventId on 200 OK', () async {
      RequestOptions? request;
      final repository = HttpInvitationsRepository(
        dio: dioResolving({'eventId': expectedEventId}, (options) {
          request = options;
        }),
      );

      final result = await repository.resolveInvitationToken(validToken);

      expect(request?.method, 'GET');
      expect(request?.path, '/invitations/$validToken');
      expect(result, expectedEventId);
    });

    test(
      'throws InvalidInvitationException immediately on empty or blank token',
      () async {
        bool called = false;
        final repository = HttpInvitationsRepository(
          dio: dioResolving({'eventId': expectedEventId}, (_) {
            called = true;
          }),
        );

        expect(
          () => repository.resolveInvitationToken('   '),
          throwsA(isA<InvalidInvitationException>()),
        );
        expect(called, isFalse);
      },
    );

    test('maps 400 Bad Request to InvalidInvitationException', () async {
      final repository = HttpInvitationsRepository(
        dio: dioRejecting(400, {
          'error': 'VALIDATION_ERROR',
          'message': 'El token de invitación es requerido',
        }),
      );

      expect(
        () => repository.resolveInvitationToken(validToken),
        throwsA(isA<InvalidInvitationException>()),
      );
    });

    test(
      'maps 404 INVITATION_NOT_FOUND to InvitationNotFoundException',
      () async {
        final repository = HttpInvitationsRepository(
          dio: dioRejecting(404, {
            'error': 'INVITATION_NOT_FOUND',
            'message': 'Invitación no encontrada',
          }),
        );

        expect(
          () => repository.resolveInvitationToken(validToken),
          throwsA(isA<InvitationNotFoundException>()),
        );
      },
    );

    test(
      'maps 404 INVITATION_UNAVAILABLE to InvitationExpiredException',
      () async {
        final repository = HttpInvitationsRepository(
          dio: dioRejecting(404, {
            'error': 'INVITATION_UNAVAILABLE',
            'message': 'Invitación no disponible',
          }),
        );

        expect(
          () => repository.resolveInvitationToken(validToken),
          throwsA(isA<InvitationExpiredException>()),
        );
      },
    );

    test(
      'maps 404 without specific error body to InvitationNotFoundException',
      () async {
        final repository = HttpInvitationsRepository(
          dio: dioRejecting(404, null),
        );

        expect(
          () => repository.resolveInvitationToken(validToken),
          throwsA(isA<InvitationNotFoundException>()),
        );
      },
    );

    test('maps connection error to NetworkInvitationException', () async {
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
      final repository = HttpInvitationsRepository(dio: dio);

      expect(
        () => repository.resolveInvitationToken(validToken),
        throwsA(isA<NetworkInvitationException>()),
      );
    });

    test('maps timeout errors to NetworkInvitationException', () async {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(requestOptions: options, type: type),
            ),
          ),
        );
        final repository = HttpInvitationsRepository(dio: dio);

        expect(
          () => repository.resolveInvitationToken(validToken),
          throwsA(isA<NetworkInvitationException>()),
        );
      }
    });

    test(
      'maps 500 Internal Server Error to UnknownInvitationException',
      () async {
        final repository = HttpInvitationsRepository(
          dio: dioRejecting(500, {'error': 'INTERNAL_ERROR'}),
        );

        expect(
          () => repository.resolveInvitationToken(validToken),
          throwsA(isA<UnknownInvitationException>()),
        );
      },
    );

    test(
      'maps unexpected 502/503 server errors to UnknownInvitationException',
      () async {
        for (final statusCode in [502, 503]) {
          final repository = HttpInvitationsRepository(
            dio: dioRejecting(statusCode, 'Bad Gateway'),
          );

          expect(
            () => repository.resolveInvitationToken(validToken),
            throwsA(isA<UnknownInvitationException>()),
          );
        }
      },
    );

    test(
      'maps malformed 200 responses where eventId is missing or empty to UnknownInvitationException',
      () async {
        final malformedBodies = [
          {},
          {'eventId': ''},
          {'eventId': '   '},
          {'eventId': 123},
          {'somethingElse': 'evt-123'},
          'not a map',
        ];

        for (final body in malformedBodies) {
          final repository = HttpInvitationsRepository(
            dio: dioResolving(body, null),
          );

          expect(
            () => repository.resolveInvitationToken(validToken),
            throwsA(isA<UnknownInvitationException>()),
          );
        }
      },
    );

    test('creates an invitation and returns its URL', () async {
      RequestOptions? request;
      final repository = HttpInvitationsRepository(
        dio: dioResolving({'invitationUrl': 'planify://invite/token-new'}, (
          options,
        ) {
          request = options;
        }, statusCode: 201),
      );

      final result = await repository.createInvitation('evt-123');

      expect(request?.method, 'POST');
      expect(request?.path, '/events/evt-123/invitations');
      expect(request?.data, isEmpty);
      expect(result, 'planify://invite/token-new');
    });

    test('maps invitation creation authorization and event errors', () async {
      final cases = <({int statusCode, dynamic body, Type matcher})>[
        (
          statusCode: 403,
          body: {'error': 'FORBIDDEN'},
          matcher: InvitationCreationForbiddenException,
        ),
        (
          statusCode: 404,
          body: {'error': 'EVENT_NOT_FOUND'},
          matcher: InvitationEventNotFoundException,
        ),
        (
          statusCode: 409,
          body: {'error': 'EVENT_UNAVAILABLE'},
          matcher: InvitationEventUnavailableException,
        ),
      ];

      for (final testCase in cases) {
        final repository = HttpInvitationsRepository(
          dio: dioRejecting(testCase.statusCode, testCase.body),
        );

        expect(
          () => repository.createInvitation('evt-123'),
          throwsA(
            isA<InvitationException>().having(
              (exception) => exception.runtimeType,
              'runtimeType',
              testCase.matcher,
            ),
          ),
        );
      }
    });

    test('maps creation network and malformed-response errors', () async {
      final networkDio = Dio();
      networkDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          ),
        ),
      );

      expect(
        () => HttpInvitationsRepository(
          dio: networkDio,
        ).createInvitation('evt-123'),
        throwsA(isA<NetworkInvitationException>()),
      );

      for (final body in [
        null,
        {},
        {'invitationUrl': ''},
        {'url': 'value'},
      ]) {
        expect(
          () => HttpInvitationsRepository(
            dio: dioResolving(body, null, statusCode: 201),
          ).createInvitation('evt-123'),
          throwsA(isA<UnknownInvitationException>()),
        );
      }
    });
  });
}
