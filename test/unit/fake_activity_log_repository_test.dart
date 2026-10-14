import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/domain/activity_type.dart';
import 'package:planify/features/activity_log/domain/unread_counts.dart';

void main() {
  group('FakeActivityLogRepository', () {
    test(
      'marca un evento y descuenta solo su grupo, de forma idempotente',
      () async {
        final repository = FakeActivityLogRepository(delay: Duration.zero);
        final before = await repository.getUnreadCounts();
        expect(before.forGroup('grp-amigos'), 12);
        await repository.markEventAsRead('evt-123');
        await repository.markEventAsRead('evt-123');
        await repository.markEventAsRead('unknown');
        final after = await repository.getUnreadCounts();
        expect(after.forEvent('evt-123'), 0);
        expect(after.forEvent('evt-asado-amigos'), 7);
        expect(after.forGroup('grp-amigos'), 7);
        expect(after.forGroup('grp-familia'), 1);
        expect(after.forGroup('grp-trabajo'), 0);
        expect(before.forEvent('evt-123'), 5);
      },
    );

    test('no produce totales negativos con seeds inconsistentes', () async {
      final repository = FakeActivityLogRepository(
        delay: Duration.zero,
        initialUnreadCounts: UnreadCounts(byEvent: {'e': 5}, byGroup: {'g': 2}),
        groupByEvent: {'e': 'g'},
      );
      await repository.markEventAsRead('e');
      expect((await repository.getUnreadCounts()).forGroup('g'), 0);
    });

    test(
      'un marcado fallido no modifica los conteos y permite reintentar',
      () async {
        final repository = FakeActivityLogRepository(
          delay: Duration.zero,
          shouldThrowMarkAsReadError: true,
        );
        await expectLater(
          repository.markEventAsRead('evt-123'),
          throwsException,
        );
        expect((await repository.getUnreadCounts()).forEvent('evt-123'), 5);
        repository.shouldThrowMarkAsReadError = false;
        await repository.markEventAsRead('evt-123');
        expect((await repository.getUnreadCounts()).forEvent('evt-123'), 0);
      },
    );

    test('el error de contadores es independiente del feed', () async {
      final repository = FakeActivityLogRepository(
        delay: Duration.zero,
        shouldThrowUnreadCountsError: true,
      );
      await expectLater(repository.getUnreadCounts(), throwsException);
      expect(await repository.listEventActivity('evt-123'), hasLength(5));
    });
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
