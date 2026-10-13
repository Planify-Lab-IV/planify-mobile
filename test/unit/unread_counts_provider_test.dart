import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/presentation/controllers/activity_log_providers.dart';

void main() {
  test(
    'obtiene los conteos del repositorio inyectado y actualiza al invalidar',
    () async {
      final repository = FakeActivityLogRepository(delay: Duration.zero);
      final container = ProviderContainer(
        overrides: [
          activityLogRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(unreadCountsProvider, (_, _) {});
      addTearDown(subscription.close);
      expect(
        (await container.read(unreadCountsProvider.future)).forEvent('evt-123'),
        5,
      );
      await repository.markEventAsRead('evt-123');
      container.invalidate(unreadCountsProvider);
      final counts = await container.read(unreadCountsProvider.future);
      expect(counts.forEvent('evt-123'), 0);
      expect(counts.forGroup('grp-amigos'), 7);
    },
  );

  test('expone el error de la consulta de contadores', () async {
    final container = ProviderContainer(
      overrides: [
        activityLogRepositoryProvider.overrideWithValue(
          FakeActivityLogRepository(
            delay: Duration.zero,
            shouldThrowUnreadCountsError: true,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(unreadCountsProvider.future),
      throwsException,
    );
    expect(container.read(unreadCountsProvider).hasError, isTrue);
  });
}
