import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/auth_exceptions.dart';
import 'package:planify/features/auth/data/http_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';

void main() {
  group('HttpAuthRepository', () {
    const responseData = {
      'user': {
        'id': 'uuid-organizer-1',
        'name': 'Dev One',
        'username': 'dev1',
        'email': 'dev1@planify.dev',
      },
      'token': 'backend-jwt-token',
    };

    HttpAuthRepository repositoryWith(
      Dio dio, {
      SecureStorage? storage,
    }) {
      return HttpAuthRepository(
        dio: dio,
        storage: storage ?? FakeSecureStorage(),
      );
    }

    Dio dioResolvingWithStatus(
      int statusCode,
      Map<String, dynamic> body,
      void Function(RequestOptions)? inspect,
    ) {
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

    Dio dioResolving(
      Map<String, dynamic> body,
      void Function(RequestOptions)? inspect,
    ) {
      return dioResolvingWithStatus(200, body, inspect);
    }

    test('returns null without a stored token and does not call /auth/me', () async {
      var requestCount = 0;
      final repository = repositoryWith(
        dioResolving({'user': {}}, (_) => requestCount++),
      );

      final session = await repository.getCurrentSession();

      expect(session, isNull);
      expect(requestCount, 0);
    });

    test('restores an organizer session from /auth/me using the stored token',
        () async {
      final storage = FakeSecureStorage();
      await storage.saveToken('stored-jwt-token');
      RequestOptions? request;
      final repository = repositoryWith(
        dioResolving({
          'user': responseData['user'],
        }, (options) => request = options),
        storage: storage,
      );

      final session = await repository.getCurrentSession();

      expect(request?.method, 'GET');
      expect(request?.path, '/auth/me');
      expect(request?.data, isNull);
      expect(session, isA<OrganizerSession>());
      final organizer = session! as OrganizerSession;
      expect(organizer.userId, 'uuid-organizer-1');
      expect(organizer.name, 'Dev One');
      expect(organizer.username, 'dev1');
      expect(organizer.email, 'dev1@planify.dev');
      expect(organizer.token, 'stored-jwt-token');
    });

    test('does not repeat /auth/me when the session is already in memory',
        () async {
      final storage = FakeSecureStorage();
      await storage.saveToken('stored-jwt-token');
      var requestCount = 0;
      final repository = repositoryWith(
        dioResolving({
          'user': responseData['user'],
        }, (_) => requestCount++),
        storage: storage,
      );

      await repository.getCurrentSession();
      await repository.getCurrentSession();

      expect(requestCount, 1);
    });

    test('rejects a malformed /auth/me success response', () async {
      final storage = FakeSecureStorage();
      await storage.saveToken('stored-jwt-token');
      final repository = repositoryWith(
        dioResolving({}, null),
        storage: storage,
      );

      expect(
        repository.getCurrentSession,
        throwsA(isA<UnknownAuthException>()),
      );
    });

    test('maps a 401 from /auth/me to an invalid stored session', () async {
      final storage = FakeSecureStorage();
      await storage.saveToken('expired-jwt-token');
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 401,
              ),
            ),
          ),
        ),
      );

      expect(
        repositoryWith(dio, storage: storage).getCurrentSession,
        throwsA(isA<InvalidStoredSessionException>()),
      );
    });

    test('maps a network failure from /auth/me to a network error', () async {
      final storage = FakeSecureStorage();
      await storage.saveToken('stored-jwt-token');
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

      expect(
        repositoryWith(dio, storage: storage).getCurrentSession,
        throwsA(isA<NetworkAuthException>()),
      );
    });

    test('maps unexpected /auth/me failures to an unknown error', () async {
      final storage = FakeSecureStorage();
      await storage.saveToken('stored-jwt-token');
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 500,
              ),
            ),
          ),
        ),
      );

      expect(
        repositoryWith(dio, storage: storage).getCurrentSession,
        throwsA(isA<UnknownAuthException>()),
      );
    });

    test(
      'sends an email unchanged as identifier and maps canonical user data',
      () async {
        RequestOptions? request;
        final repository = repositoryWith(
          dioResolving(responseData, (options) => request = options),
        );

        final session = await repository.login(
          identifier: 'dev1@planify.dev',
          password: 'DevPass123!',
        );

        expect(request?.method, 'POST');
        expect(request?.path, '/auth/login');
        expect(request?.data, {
          'identifier': 'dev1@planify.dev',
          'password': 'DevPass123!',
        });
        expect(session, isA<OrganizerSession>());
        final organizer = session as OrganizerSession;
        expect(organizer.userId, 'uuid-organizer-1');
        expect(organizer.name, 'Dev One');
        expect(organizer.username, 'dev1');
        expect(organizer.email, 'dev1@planify.dev');
        expect(organizer.token, 'backend-jwt-token');
        expect(organizer.role, UserRole.organizer);
      },
    );

    test('sends a username unchanged as identifier', () async {
      RequestOptions? request;
      final repository = repositoryWith(
        dioResolving(responseData, (options) => request = options),
      );

      await repository.login(identifier: 'dev1', password: 'DevPass123!');

      expect(request?.data, {'identifier': 'dev1', 'password': 'DevPass123!'});
    });

    test('maps a 401 response to invalid credentials', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 401,
              ),
            ),
          ),
        ),
      );

      expect(
        () => repositoryWith(dio).login(identifier: 'dev1', password: 'wrong'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('maps connection errors to network errors', () async {
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

      expect(
        () => repositoryWith(
          dio,
        ).login(identifier: 'dev1', password: 'DevPass123!'),
        throwsA(isA<NetworkAuthException>()),
      );
    });

    test('rejects malformed success responses', () async {
      final repository = repositoryWith(dioResolving({'token': 'token'}, null));

      expect(
        () => repository.login(identifier: 'dev1', password: 'DevPass123!'),
        throwsA(isA<UnknownAuthException>()),
      );
    });

    test('rejects a user missing a canonical organizer field', () async {
      final repository = repositoryWith(
        dioResolving({
          'user': {
            'id': 'uuid-organizer-1',
            'name': 'Dev One',
            'username': 'dev1',
          },
          'token': 'backend-jwt-token',
        }, null),
      );

      expect(
        () => repository.login(identifier: 'dev1', password: 'DevPass123!'),
        throwsA(isA<UnknownAuthException>()),
      );
    });

    test('creates an anonymous participant and maps its session', () async {
      RequestOptions? request;
      final repository = repositoryWith(
        dioResolvingWithStatus(201, {
          'participant': {
            'id': 'participant-a',
            'eventId': 'event-a',
            'username': 'Gil',
            'isAnonymous': true,
          },
          'token': 'participant-session-token',
        }, (options) => request = options),
      );

      final session = await repository.loginAnonymously(
        name: 'Gil',
        pin: '1234',
        eventId: 'event-a',
      );

      expect(request?.method, 'POST');
      expect(request?.path, '/events/event-a/participants/anonymous');
      expect(request?.data, {'name': 'Gil', 'pin': '1234'});
      expect(session, isA<AnonymousSession>());
      final anonymous = session as AnonymousSession;
      expect(anonymous.participantId, 'participant-a');
      expect(anonymous.name, 'Gil');
      expect(anonymous.eventId, 'event-a');
      expect(anonymous.token, 'participant-session-token');
    });

    test('trims name, pin and eventId before sending HTTP request', () async {
      RequestOptions? request;
      final repository = repositoryWith(
        dioResolvingWithStatus(201, {
          'participant': {
            'id': 'participant-a',
            'eventId': 'event-a',
            'username': 'Gil',
            'isAnonymous': true,
          },
          'token': 'participant-session-token',
        }, (options) => request = options),
      );

      await repository.loginAnonymously(
        name: '  Gil  ',
        pin: ' 1234 ',
        eventId: ' event-a ',
      );

      expect(request?.path, '/events/event-a/participants/anonymous');
      expect(request?.data, {'name': 'Gil', 'pin': '1234'});
    });

    test(
      'maps a re-entry response to the existing participant session',
      () async {
        final repository = repositoryWith(
          dioResolvingWithStatus(200, {
            'participant': {
              'id': 'participant-a',
              'eventId': 'event-a',
              'username': 'Gil',
              'isAnonymous': true,
            },
            'token': 'new-participant-session-token',
          }, null),
        );

        final session = await repository.loginAnonymously(
          name: 'Gil',
          pin: '1234',
          eventId: 'event-a',
        );

        expect(session, isA<AnonymousSession>());
        expect((session as AnonymousSession).participantId, 'participant-a');
        expect(session.token, 'new-participant-session-token');
      },
    );

    test(
      'keeps participants scoped to the event returned by the backend',
      () async {
        final repository = repositoryWith(
          dioResolvingWithStatus(201, {
            'participant': {
              'id': 'participant-b',
              'eventId': 'event-b',
              'username': 'Gil',
              'isAnonymous': true,
            },
            'token': 'event-b-token',
          }, null),
        );

        final session = await repository.loginAnonymously(
          name: 'Gil',
          pin: '1234',
          eventId: 'event-b',
        );

        expect(session, isA<AnonymousSession>());
        final anonymous = session as AnonymousSession;
        expect(anonymous.participantId, 'participant-b');
        expect(anonymous.eventId, 'event-b');
      },
    );

    test(
      'maps anonymous invalid PIN responses to InvalidPinException',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 401,
                ),
              ),
            ),
          ),
        );

        expect(
          () => repositoryWith(
            dio,
          ).loginAnonymously(name: 'Gil', pin: '9999', eventId: 'event-a'),
          throwsA(isA<InvalidPinException>()),
        );
      },
    );

    test('maps an absent event to AnonymousEventNotFoundException', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 404,
              ),
            ),
          ),
        ),
      );

      expect(
        () => repositoryWith(
          dio,
        ).loginAnonymously(name: 'Gil', pin: '1234', eventId: 'event-missing'),
        throwsA(isA<AnonymousEventNotFoundException>()),
      );
    });

    test(
      'maps an unavailable event (409) to AnonymousEventUnavailableException',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 409,
                ),
              ),
            ),
          ),
        );

        expect(
          () => repositoryWith(dio).loginAnonymously(
            name: 'Gil',
            pin: '1234',
            eventId: 'event-unavailable',
          ),
          throwsA(isA<AnonymousEventUnavailableException>()),
        );
      },
    );

    test('rejects malformed anonymous responses', () async {
      final repository = repositoryWith(
        dioResolving({
          'participant': {
            'id': 'participant-a',
            'eventId': 'event-a',
            'username': 'Gil',
            'isAnonymous': false,
          },
          'token': 'token',
        }, null),
      );

      expect(
        () => repository.loginAnonymously(
          name: 'Gil',
          pin: '1234',
          eventId: 'event-a',
        ),
        throwsA(isA<UnknownAuthException>()),
      );
    });

    test('rejects an anonymous response for another event', () async {
      final repository = repositoryWith(
        dioResolving({
          'participant': {
            'id': 'participant-b',
            'eventId': 'event-b',
            'username': 'Gil',
            'isAnonymous': true,
          },
          'token': 'token',
        }, null),
      );

      expect(
        () => repository.loginAnonymously(
          name: 'Gil',
          pin: '1234',
          eventId: 'event-a',
        ),
        throwsA(isA<UnknownAuthException>()),
      );
    });

    test('requires an event ID before creating an anonymous session', () async {
      expect(
        () => repositoryWith(Dio()).loginAnonymously(name: 'Gil', pin: '1234'),
        throwsA(isA<UnknownAuthException>()),
      );
    });
  });
}
