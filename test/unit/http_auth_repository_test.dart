import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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

    HttpAuthRepository repositoryWith(Dio dio) {
      return HttpAuthRepository(dio: dio);
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
