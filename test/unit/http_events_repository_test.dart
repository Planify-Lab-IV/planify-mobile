import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/data/event_exceptions.dart';
import 'package:planify/features/events/data/http_events_repository.dart';
import 'package:planify/features/events/domain/attendance_status.dart';
import 'package:planify/features/events/domain/event_draft.dart';
import 'package:planify/features/events/domain/event_status.dart';

void main() {
  group('HttpEventsRepository', () {
    const eventResponse = {
      'id': 'evt-1',
      'name': 'Asado',
      'location': 'Casa',
      'organizerId': 'usr-1',
      'groupId': 'grp-1',
      'status': 'active',
      'createdAt': '2026-09-09T12:00:00.000Z',
      'updatedAt': '2026-09-09T12:00:00.000Z',
      'participants': [
        {
          'eventId': 'evt-1',
          'userId': 'usr-1',
          'username': 'dev1',
          'isAnonymous': false,
          'isOrganizer': true,
        },
        {
          'eventId': 'evt-1',
          'userId': null,
          'username': 'Invitado',
          'isAnonymous': true,
          'isOrganizer': false,
        },
      ],
    };

    Dio dioResolving(dynamic body, void Function(RequestOptions)? inspect) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            inspect?.call(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 201,
                data: body,
              ),
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
            ),
          ),
        ),
      );
      return dio;
    }

    test('sends the existing group payload and maps the full event', () async {
      RequestOptions? request;
      final repository = HttpEventsRepository(
        dio: dioResolving(eventResponse, (options) => request = options),
      );
      const draft = EventDraft(
        name: 'Asado',
        location: 'Casa',
        selectedGroupId: 'grp-1',
      );

      final event = await repository.createEvent(draft);

      expect(request?.method, 'POST');
      expect(request?.path, '/events');
      expect(request?.data, {
        'name': 'Asado',
        'location': 'Casa',
        'groupId': 'grp-1',
      });
      expect(event.status, EventStatus.active);
      expect(event.updatedAt, DateTime.parse('2026-09-09T12:00:00.000Z'));
      expect(event.participants, hasLength(2));
      expect(event.participants.first.username, 'dev1');
      expect(event.participants.last.userId, isNull);
      expect(event.participants.last.isAnonymous, isTrue);
    });

    test('sends the new group payload without an organizer ID', () async {
      RequestOptions? request;
      final repository = HttpEventsRepository(
        dio: dioResolving(eventResponse, (options) => request = options),
      );
      const draft = EventDraft(
        name: 'Asado',
        location: 'Casa',
        isNewGroup: true,
        newGroupName: 'Amigos',
        newGroupMembers: ['dev2', 'dev3'],
      );

      await repository.createEvent(draft);

      expect(request?.data, {
        'name': 'Asado',
        'location': 'Casa',
        'newGroupName': 'Amigos',
        'memberIdentifiers': ['dev2', 'dev3'],
      });
    });

    test('rejects malformed event responses', () async {
      final repository = HttpEventsRepository(
        dio: dioResolving({'id': 'evt-1'}, null),
      );
      const draft = EventDraft(
        name: 'Asado',
        location: 'Casa',
        selectedGroupId: 'grp-1',
      );

      expect(
        () => repository.createEvent(draft),
        throwsA(isA<InvalidEventResponseException>()),
      );
    });

    test('maps connection errors to a network exception', () async {
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
      final repository = HttpEventsRepository(dio: dio);
      const draft = EventDraft(
        name: 'Asado',
        location: 'Casa',
        selectedGroupId: 'grp-1',
      );

      expect(
        () => repository.createEvent(draft),
        throwsA(isA<NetworkEventException>()),
      );
    });

    group('getEvent', () {
      test(
        'executes GET /events/:eventId and maps the full event with participants',
        () async {
          RequestOptions? request;
          final repository = HttpEventsRepository(
            dio: dioResolving(eventResponse, (options) => request = options),
          );

          final event = await repository.getEvent('evt-1');

          expect(request?.method, 'GET');
          expect(request?.path, '/events/evt-1');
          expect(event, isNotNull);
          expect(event!.id, 'evt-1');
          expect(event.name, 'Asado');
          expect(event.location, 'Casa');
          expect(event.organizerId, 'usr-1');
          expect(event.groupId, 'grp-1');
          expect(event.status, EventStatus.active);
          expect(event.createdAt, DateTime.parse('2026-09-09T12:00:00.000Z'));
          expect(event.updatedAt, DateTime.parse('2026-09-09T12:00:00.000Z'));
          expect(event.participants, hasLength(2));
          expect(event.participants[0].userId, 'usr-1');
          expect(event.participants[0].username, 'dev1');
          expect(event.participants[0].isAnonymous, isFalse);
          expect(event.participants[0].isOrganizer, isTrue);
          expect(event.participants[1].userId, isNull);
          expect(event.participants[1].username, 'Invitado');
          expect(event.participants[1].isAnonymous, isTrue);
          expect(event.participants[1].isOrganizer, isFalse);
        },
      );

      test('maps cancelled status correctly', () async {
        final cancelledResponse = Map<String, dynamic>.from(eventResponse)
          ..['status'] = 'cancelled';
        final repository = HttpEventsRepository(
          dio: dioResolving(cancelledResponse, null),
        );

        final event = await repository.getEvent('evt-1');

        expect(event, isNotNull);
        expect(event!.status, EventStatus.cancelled);
        expect(event.isCancelled, isTrue);
      });

      test('returns null when the backend responds with 404', () async {
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
        final repository = HttpEventsRepository(dio: dio);

        final event = await repository.getEvent('evt-missing');

        expect(event, isNull);
      });

      test('maps connection errors to NetworkEventException', () async {
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
        final repository = HttpEventsRepository(dio: dio);

        expect(
          () => repository.getEvent('evt-1'),
          throwsA(isA<NetworkEventException>()),
        );
      });

      test(
        'maps malformed event response to InvalidEventResponseException',
        () async {
          final repository = HttpEventsRepository(
            dio: dioResolving({'invalid': 'data'}, null),
          );

          expect(
            () => repository.getEvent('evt-1'),
            throwsA(isA<InvalidEventResponseException>()),
          );
        },
      );

      test(
        'rejects blank event IDs with InvalidEventResponseException',
        () async {
          final repository = HttpEventsRepository(dio: Dio());

          expect(
            () => repository.getEvent('   '),
            throwsA(isA<InvalidEventResponseException>()),
          );
        },
      );
    });

    group('cancel', () {
      test('executes PUT /events/:eventId', () async {
        RequestOptions? request;
        final repository = HttpEventsRepository(
          dio: dioResolving(null, (options) => request = options),
        );

        await repository.cancel('evt-1');

        expect(request?.method, 'PUT');
        expect(request?.path, '/events/evt-1/cancel');
      });

      test('maps a missing event to EventNotFoundException', () async {
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
        final repository = HttpEventsRepository(dio: dio);

        expect(
          () => repository.cancel('evt-missing'),
          throwsA(isA<EventNotFoundException>()),
        );
      });

      test('maps connection errors to NetworkEventException', () async {
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
        final repository = HttpEventsRepository(dio: dio);

        expect(
          () => repository.cancel('evt-1'),
          throwsA(isA<NetworkEventException>()),
        );
      });

      test('maps non-recoverable HTTP errors to EventCancellationException',
          () async {
        for (final statusCode in [401, 403, 409, 500, 503]) {
          final repository = HttpEventsRepository(
            dio: dioRejecting(statusCode),
          );

          await expectLater(
            repository.cancel('evt-1'),
            throwsA(isA<EventCancellationException>()),
          );
        }
      });

      test('rejects blank event IDs before sending a request', () async {
        final repository = HttpEventsRepository(dio: Dio());

        expect(
          () => repository.cancel('   '),
          throwsA(isA<InvalidEventResponseException>()),
        );
      });
    });

    test('reports attendance methods as unsupported', () async {
      final repository = HttpEventsRepository(dio: Dio());

      expect(
        () => repository.getCurrentUserAttendance('evt-1'),
        throwsA(isA<UnsupportedEventOperationException>()),
      );
      expect(
        () => repository.updateCurrentUserAttendance(
          'evt-1',
          AttendanceResponse.confirmed,
        ),
        throwsA(isA<UnsupportedEventOperationException>()),
      );
    });
  });
}
