import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/domain/event_status.dart';
import 'package:planify/features/groups/data/group_exceptions.dart';
import 'package:planify/features/groups/data/http_groups_overview_repository.dart';

void main() {
  group('HttpGroupsOverviewRepository', () {
    Dio dioResolving(dynamic body, void Function(RequestOptions)? inspect) {
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

    const validEvent = {
      'id': 'evt-1',
      'name': 'Asado',
      'location': 'Casa',
      'status': 'confirmed',
      'startDateTime': '2026-12-20T21:30:00.000Z',
    };

    test('requests and maps the authenticated user groups overview', () async {
      RequestOptions? request;
      final repository = HttpGroupsOverviewRepository(
        dio: dioResolving([
          {
            'id': 'grp-1',
            'name': 'Amigos',
            'memberCount': 3,
            'events': [validEvent],
          },
        ], (options) => request = options),
      );

      final groups = await repository.getMyGroupsOverview();

      expect(request?.method, 'GET');
      expect(request?.path, '/me/groups/overview');
      expect(groups, hasLength(1));
      expect(groups.single.id, 'grp-1');
      expect(groups.single.name, 'Amigos');
      expect(groups.single.memberCount, 3);
      expect(groups.single.events, hasLength(1));
      expect(groups.single.events.single.status, EventStatus.confirmed);
      expect(
        groups.single.events.single.startDateTime,
        DateTime.parse(validEvent['startDateTime']!).toLocal(),
      );
    });

    test(
      'maps groups without events and events without a scheduled date',
      () async {
        final repository = HttpGroupsOverviewRepository(
          dio: dioResolving([
            {'id': 'empty', 'name': 'Vacío', 'memberCount': 0, 'events': []},
            {
              'id': 'unscheduled',
              'name': 'Pendientes',
              'memberCount': 2,
              'events': [
                {...validEvent, 'status': 'active', 'startDateTime': null},
              ],
            },
          ], null),
        );

        final groups = await repository.getMyGroupsOverview();

        expect(groups.first.events, isEmpty);
        expect(groups.last.events.single.status, EventStatus.active);
        expect(groups.last.events.single.startDateTime, isNull);
      },
    );

    test('rejects malformed responses and unknown event statuses', () async {
      final invalidResponses = [
        {'id': 'grp-1'},
        [
          {'id': 'grp-1', 'name': 'Amigos', 'memberCount': -1, 'events': []},
        ],
        [
          {
            'id': 'grp-1',
            'name': 'Amigos',
            'memberCount': 1,
            'events': [
              {...validEvent, 'status': 'postponed'},
            ],
          },
        ],
        [
          {
            'id': 'grp-1',
            'name': 'Amigos',
            'memberCount': 1,
            'events': [
              {...validEvent, 'startDateTime': 'not-a-date'},
            ],
          },
        ],
      ];

      for (final response in invalidResponses) {
        final repository = HttpGroupsOverviewRepository(
          dio: dioResolving(response, null),
        );

        await expectLater(
          repository.getMyGroupsOverview(),
          throwsA(isA<InvalidGroupsResponseException>()),
        );
      }
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
      final repository = HttpGroupsOverviewRepository(dio: dio);

      expect(
        repository.getMyGroupsOverview,
        throwsA(isA<NetworkGroupsException>()),
      );
    });
  });
}
