import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/domain/activity_type.dart';

void main() {
  group('FakeActivityLogRepository', () {
    test(
      'devuelve los cuatro tipos conocidos y unknown para evt-123',
      () async {
        final repository = FakeActivityLogRepository(delay: Duration.zero);

        final entries = await repository.listEventActivity('evt-123');

        expect(entries, hasLength(5));
        expect(
          entries.map((entry) => entry.type),
          containsAll(<ActivityType>[
            ActivityType.taskCreated,
            ActivityType.availabilityUpdated,
            ActivityType.expenseCreated,
            ActivityType.scheduleConfirmed,
            ActivityType.unknown,
          ]),
        );
        expect(
          entries,
          orderedEquals(
            [...entries]..sort(
              (first, second) => second.createdAt.compareTo(first.createdAt),
            ),
          ),
        );
      },
    );

    test('devuelve una lista vacía para un evento sin actividad', () async {
      final repository = FakeActivityLogRepository(delay: Duration.zero);

      final entries = await repository.listEventActivity('evt-fake-demo');

      expect(entries, isEmpty);
    });

    test('devuelve el feed demo para un evento recién creado', () async {
      final repository = FakeActivityLogRepository(delay: Duration.zero);

      final entries = await repository.listEventActivity('evt-9876');

      expect(entries, hasLength(5));
      expect(entries.first.id, 'activity-evt-123-1');
    });

    test('simula un error cuando se configura shouldThrowError', () async {
      final repository = FakeActivityLogRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );

      expect(repository.listEventActivity('evt-123'), throwsException);
    });
  });
}
