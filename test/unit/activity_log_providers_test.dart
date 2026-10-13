import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/data/http_activity_log_repository.dart';
import 'package:planify/features/activity_log/presentation/controllers/activity_log_providers.dart';
import 'package:planify/features/activity_log/presentation/controllers/event_activity_state.dart';

void main() {
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
