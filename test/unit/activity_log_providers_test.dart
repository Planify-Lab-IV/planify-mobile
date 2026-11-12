import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/data/http_activity_log_repository.dart';
import 'package:planify/features/activity_log/presentation/controllers/activity_log_providers.dart';
import 'package:planify/features/activity_log/presentation/controllers/event_activity_state.dart';

void main() {
  test(
    'HTTP feed success marks read and refreshes real unread counts',
    () async {
      final requests = <String>[];
      final feedLoaded = Completer<void>();
      final countsUpdated = Completer<void>();
      final dio = Dio();
      var marked = false;
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add('${options.method} ${options.path}');
            if (options.path == '/events/evt-123/activity-log/read') {
              expect(options.method, 'POST');
              marked = true;
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: options.path == '/me/unread-counts'
                    ? {
                        'events': [
                          {'eventId': 'evt-123', 'unreadCount': marked ? 0 : 5},
                        ],
                        'groups': [
                          {
                            'groupId': 'grp-amigos',
                            'unreadCount': marked ? 7 : 12,
                          },
                        ],
                      }
                    : {'entries': []},
                statusCode: options.method == 'POST' ? 204 : 200,
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [dioClientProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);
      final countsSubscription = container.listen(unreadCountsProvider, (
        _,
        next,
      ) {
        final counts = next.asData?.value;
        if (counts?.forEvent('evt-123') == 0 && !countsUpdated.isCompleted) {
          countsUpdated.complete();
        }
      });
      addTearDown(countsSubscription.close);
      final before = await container.read(unreadCountsProvider.future);
      expect(before.forEvent('evt-123'), 5);
      expect(before.forGroup('grp-amigos'), 12);

      final provider = eventActivityNotifierProvider('evt-123');
      final feedSubscription = container.listen(provider, (_, next) {
        if (next.loadStatus == EventActivityLoadStatus.success &&
            !feedLoaded.isCompleted) {
          feedLoaded.complete();
        }
      });
      addTearDown(feedSubscription.close);
      await feedLoaded.future;
      await countsUpdated.future.timeout(const Duration(seconds: 5));

      expect(
        container.read(provider).loadStatus,
        EventActivityLoadStatus.success,
      );
      final after = await container.read(unreadCountsProvider.future);
      expect(after.forEvent('evt-123'), 0);
      expect(after.forGroup('grp-amigos'), 7);
      container.invalidate(unreadCountsProvider);
      expect(
        (await container.read(
          unreadCountsProvider.future,
        )).forGroup('grp-amigos'),
        7,
      );
      expect(requests, [
        'GET /me/unread-counts',
        'GET /events/evt-123/activity-log',
        'POST /events/evt-123/activity-log/read',
        'GET /me/unread-counts',
        'GET /me/unread-counts',
      ]);
    },
  );

  test('activity log provider uses the shared Dio client', () async {
    RequestOptions? request;
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: {'entries': []},
              statusCode: 200,
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    final repository = container.read(activityLogRepositoryProvider);
    expect(repository, isA<HttpActivityLogRepository>());
    expect((repository as HttpActivityLogRepository).dio, same(dio));
    expect(await repository.listEventActivity('evt-1'), isEmpty);
    expect(request?.path, '/events/evt-1/activity-log');
  });

  test('repository overrides keep the notifier independent of Dio', () async {
    final repository = FakeActivityLogRepository(delay: Duration.zero);
    final container = ProviderContainer(
      overrides: [
        activityLogRepositoryProvider.overrideWithValue(repository),
        dioClientProvider.overrideWith((ref) {
          fail('The fake override must not initialize the HTTP client');
        }),
      ],
    );
    addTearDown(container.dispose);
    final provider = eventActivityNotifierProvider('evt-123');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(provider).loadStatus,
      EventActivityLoadStatus.success,
    );
    expect(container.read(provider).entries, hasLength(5));
  });
}
