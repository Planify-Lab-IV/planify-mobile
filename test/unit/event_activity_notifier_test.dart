import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/domain/activity_entry.dart';
import 'package:planify/features/activity_log/domain/activity_log_repository.dart';
import 'package:planify/features/activity_log/presentation/controllers/event_activity_notifier.dart';
import 'package:planify/features/activity_log/presentation/controllers/event_activity_state.dart';

void main() {
  group('EventActivityNotifier', () {
    test('carga la actividad del evento al crearse', () async {
      final notifier = EventActivityNotifier(
        repository: FakeActivityLogRepository(delay: Duration.zero),
        eventId: 'evt-123',
      );

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.loadStatus, EventActivityLoadStatus.success);
      expect(notifier.state.entries, hasLength(5));
      notifier.dispose();
    });

    test('expone error controlado si el repositorio falla', () async {
      final notifier = EventActivityNotifier(
        repository: FakeActivityLogRepository(
          delay: Duration.zero,
          shouldThrowError: true,
        ),
        eventId: 'evt-123',
      );

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.loadStatus, EventActivityLoadStatus.error);
      expect(notifier.state.entries, isEmpty);
      notifier.dispose();
    });

    test('reload vuelve a consultar el repositorio', () async {
      final repository = _CountingActivityLogRepository();
      final notifier = EventActivityNotifier(
        repository: repository,
        eventId: 'evt-123',
      );

      await Future<void>.delayed(Duration.zero);
      await notifier.reload();

      expect(repository.callCount, 2);
      expect(notifier.state.loadStatus, EventActivityLoadStatus.success);
      notifier.dispose();
    });
  });
}

class _CountingActivityLogRepository implements ActivityLogRepository {
  int callCount = 0;

  @override
  Future<List<ActivityEntry>> listEventActivity(String eventId) async {
    callCount++;
    return const <ActivityEntry>[];
  }
}
