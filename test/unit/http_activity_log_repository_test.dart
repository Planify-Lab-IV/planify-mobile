import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/activity_log/data/activity_log_exceptions.dart';
import 'package:planify/features/activity_log/data/http_activity_log_repository.dart';
import 'package:planify/features/activity_log/domain/activity_type.dart';

void main() {
  Dio dioResolving(
    dynamic body, [
    void Function(RequestOptions options)? inspect,
  ]) {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
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

  Map<String, dynamic> entry() => {
    'id': 'activity-1',
    'type': 'task_created',
    'actor': {'participantId': 'participant-1', 'username': 'dev1'},
    'createdAt': '2026-10-13T15:00:00.000Z',
    'payload': {'taskId': 'task-1', 'title': 'Comprar bebidas'},
  };

  group('HttpActivityLogRepository', () {
    test('loads entries using the backend activity log contract', () async {
      RequestOptions? request;
      final repository = HttpActivityLogRepository(
        dio: dioResolving({
          'entries': [entry()],
        }, (options) => request = options),
      );

      final entries = await repository.listEventActivity('evt-1');

      expect(request?.method, 'GET');
      expect(request?.path, '/events/evt-1/activity-log');
      expect(entries, hasLength(1));
      expect(entries.single.id, 'activity-1');
      expect(entries.single.type, ActivityType.taskCreated);
      expect(entries.single.actorParticipantId, 'participant-1');
      expect(entries.single.actorUsername, 'dev1');
      expect(entries.single.payload, {
        'taskId': 'task-1',
        'title': 'Comprar bebidas',
      });
      expect(
        entries.single.createdAt,
        DateTime.parse('2026-10-13T15:00:00.000Z').toLocal(),
      );
      expect(entries.single.createdAt.isUtc, isFalse);
    });

    test('accepts an event without activity', () async {
      final repository = HttpActivityLogRepository(
        dio: dioResolving({'entries': []}),
      );
      expect(await repository.listEventActivity('evt-1'), isEmpty);
    });

    test(
      'maps the four backend types and preserves payloads and order',
      () async {
        final backendEntries = [
          entry()
            ..['id'] = 'schedule-1'
            ..['type'] = 'schedule_confirmed'
            ..['createdAt'] = '2026-10-13T18:00:00.000Z'
            ..['payload'] = {'startDateTime': '2026-10-20T21:00:00.000Z'},
          entry()
            ..['id'] = 'expense-1'
            ..['type'] = 'expense_created'
            ..['createdAt'] = '2026-10-13T17:00:00.000Z'
            ..['payload'] = {
              'expenseId': 'expense-1',
              'description': 'Bebidas',
              'totalAmountCents': 24500,
            },
          entry()
            ..['id'] = 'availability-1'
            ..['type'] = 'availability_updated'
            ..['createdAt'] = '2026-10-13T16:00:00.000Z'
            ..['payload'] = {'slotCount': 3},
          entry(),
        ];
        final repository = HttpActivityLogRepository(
          dio: dioResolving({'entries': backendEntries}),
        );

        final entries = await repository.listEventActivity('evt-1');

        expect(entries.map((entry) => entry.type), [
          ActivityType.scheduleConfirmed,
          ActivityType.expenseCreated,
          ActivityType.availabilityUpdated,
          ActivityType.taskCreated,
        ]);
        expect(
          entries.map((entry) => entry.id),
          backendEntries.map((entry) => entry['id']),
        );
        expect(
          entries.map((entry) => entry.payload),
          backendEntries.map((entry) => entry['payload']),
        );
      },
    );

    test('does not reorder backend entries with the same timestamp', () async {
      final repository = HttpActivityLogRepository(
        dio: dioResolving({
          'entries': [entry()..['id'] = 'z', entry()..['id'] = 'a'],
        }),
      );
      final entries = await repository.listEventActivity('evt-1');
      expect(entries.map((entry) => entry.id), ['z', 'a']);
    });

    test('preserves an unknown type as a generic activity', () async {
      final repository = HttpActivityLogRepository(
        dio: dioResolving({
          'entries': [entry()..['type'] = 'participant_joined'],
        }),
      );
      final entries = await repository.listEventActivity('evt-1');
      expect(entries.single.type, ActivityType.unknown);
      expect(entries.single.actorUsername, 'dev1');
      expect(entries.single.payload['title'], 'Comprar bebidas');
    });

    test('normalizes whitespace around the event id', () async {
      RequestOptions? request;
      final repository = HttpActivityLogRepository(
        dio: dioResolving({'entries': []}, (options) => request = options),
      );
      await repository.listEventActivity(' evt-1 ');
      expect(request?.path, '/events/evt-1/activity-log');
    });

    test('rejects an empty event id before making a request', () async {
      var requested = false;
      final repository = HttpActivityLogRepository(
        dio: dioResolving({'entries': []}, (_) => requested = true),
      );
      await expectLater(
        repository.listEventActivity('  '),
        throwsA(isA<InvalidActivityLogResponseException>()),
      );
      expect(requested, isFalse);
    });

    test('normalizes a null payload to an empty map', () async {
      final repository = HttpActivityLogRepository(
        dio: dioResolving({
          'entries': [entry()..['payload'] = null],
        }),
      );
      expect((await repository.listEventActivity('evt-1')).single.payload, {});
    });

    final malformedResponses = <String, dynamic>{
      'null body': null,
      'list body': [],
      'missing entries': {},
      'null entries': {'entries': null},
      'non-list entries': {'entries': {}},
      'non-object entry': {
        'entries': [null],
      },
    };
    for (final malformed in malformedResponses.entries) {
      test('rejects ${malformed.key}', () async {
        final repository = HttpActivityLogRepository(
          dio: dioResolving(malformed.value),
        );
        await expectLater(
          repository.listEventActivity('evt-1'),
          throwsA(isA<InvalidActivityLogResponseException>()),
        );
      });
    }

    for (final field in ['id', 'type', 'actor', 'createdAt']) {
      test('rejects an entry missing $field', () async {
        final repository = HttpActivityLogRepository(
          dio: dioResolving({
            'entries': [entry()..remove(field)],
          }),
        );
        await expectLater(
          repository.listEventActivity('evt-1'),
          throwsA(isA<InvalidActivityLogResponseException>()),
        );
      });
    }

    final invalidFields = <String, Map<String, dynamic>>{
      'numeric id': {'id': 1},
      'blank id': {'id': ' '},
      'non-string type': {'type': 1},
      'non-object actor': {'actor': 'dev1'},
      'missing participant id': {
        'actor': {'username': 'dev1'},
      },
      'missing username': {
        'actor': {'participantId': 'participant-1'},
      },
      'non-string participant id': {
        'actor': {'participantId': 1, 'username': 'dev1'},
      },
      'blank username': {
        'actor': {'participantId': 'participant-1', 'username': ' '},
      },
      'non-string username': {
        'actor': {'participantId': 'participant-1', 'username': 1},
      },
      'non-string date': {'createdAt': 1},
      'invalid date': {'createdAt': 'not-a-date'},
      'non-map payload': {'payload': []},
      'non-string payload key': {
        'payload': {1: 'value'},
      },
    };
    for (final invalid in invalidFields.entries) {
      test('rejects ${invalid.key}', () async {
        final repository = HttpActivityLogRepository(
          dio: dioResolving({
            'entries': [entry()..addAll(invalid.value)],
          }),
        );
        await expectLater(
          repository.listEventActivity('evt-1'),
          throwsA(isA<InvalidActivityLogResponseException>()),
        );
      });
    }

    test('rejects the whole response when one entry is malformed', () async {
      final repository = HttpActivityLogRepository(
        dio: dioResolving({
          'entries': [entry(), entry()..remove('id')],
        }),
      );
      await expectLater(
        repository.listEventActivity('evt-1'),
        throwsA(isA<InvalidActivityLogResponseException>()),
      );
    });

    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.badResponse,
    ]) {
      test('maps $type to the appropriate exception', () async {
        final dio = Dio();
        addTearDown(() => dio.close(force: true));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                type: type,
                response: type == DioExceptionType.badResponse
                    ? Response<dynamic>(
                        requestOptions: options,
                        statusCode: 500,
                      )
                    : null,
              ),
            ),
          ),
        );
        final repository = HttpActivityLogRepository(dio: dio);
        await expectLater(
          repository.listEventActivity('evt-1'),
          throwsA(
            type == DioExceptionType.badResponse
                ? isA<InvalidActivityLogResponseException>()
                : isA<NetworkActivityLogException>(),
          ),
        );
      });
    }
  });
}
