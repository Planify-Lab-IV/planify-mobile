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

    test('throws InvalidInvitationException immediately on empty or blank token', () async {
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
    });

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

    test('maps 404 INVITATION_NOT_FOUND to InvitationNotFoundException', () async {
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
    });

    test('maps 404 INVITATION_UNAVAILABLE to InvitationExpiredException', () async {
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
    });

    test('maps 404 without specific error body to InvitationNotFoundException', () async {
      final repository = HttpInvitationsRepository(
        dio: dioRejecting(404, null),
      );

      expect(
        () => repository.resolveInvitationToken(validToken),
        throwsA(isA<InvitationNotFoundException>()),
      );
    });

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
              DioException(
                requestOptions: options,
                type: type,
              ),
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

    test('rejects malformed 200 responses where eventId is missing or empty', () async {
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
          throwsA(isA<InvalidInvitationException>()),
        );
      }
    });
  });
}
