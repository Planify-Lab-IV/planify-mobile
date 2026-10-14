import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/domain/activity_entry.dart';
import 'package:planify/features/activity_log/domain/activity_log_repository.dart';
import 'package:planify/features/activity_log/domain/unread_counts.dart';
import 'package:planify/features/activity_log/presentation/controllers/event_activity_notifier.dart';
import 'package:planify/features/activity_log/presentation/controllers/activity_log_providers.dart';
import 'package:planify/features/activity_log/presentation/controllers/event_activity_state.dart';

void main() {
  group('EventActivityNotifier', () {
    test(
      'marca solo después del feed exitoso e invalida después del marcado',
      () async {
        final repository = _CountingActivityLogRepository()
          ..pendingFeed = Completer()
          ..pendingMark = Completer();
        var invalidations = 0;
        final notifier = EventActivityNotifier(
          repository: repository,
          eventId: 'evt-123',
          onUnreadCountsChanged: () => invalidations++,
        );
        addTearDown(notifier.dispose);
        expect(repository.readEventIds, isEmpty);
        repository.pendingFeed!.complete([]);
        await Future<void>.delayed(Duration.zero);
        expect(notifier.state.isSuccess, isTrue);
        expect(repository.readEventIds, ['evt-123']);
        expect(invalidations, 0);
        repository.pendingMark!.complete();
        await Future<void>.delayed(Duration.zero);
        expect(invalidations, 1);
      },
    );

    test('no marca ni invalida si falla el feed', () async {
      final repository = _CountingActivityLogRepository()..failFeed = true;
      var invalidations = 0;
      final notifier = EventActivityNotifier(
        repository: repository,
        eventId: 'evt-123',
        onUnreadCountsChanged: () => invalidations++,
      );
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.hasLoadError, isTrue);
      expect(repository.readEventIds, isEmpty);
      expect(invalidations, 0);
    });
    test('el provider del feed invalida los contadores compartidos', () async {
      final container = ProviderContainer(
        overrides: [
          activityLogRepositoryProvider.overrideWithValue(
            FakeActivityLogRepository(delay: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);
      final countsSubscription = container.listen(
        unreadCountsProvider,
        (_, _) {},
      );
      addTearDown(countsSubscription.close);
      expect(
        (await container.read(unreadCountsProvider.future)).forEvent('evt-123'),
        5,
      );
      final feedSubscription = container.listen(
        eventActivityNotifierProvider('evt-123'),
        (_, _) {},
      );
      addTearDown(feedSubscription.close);
      await Future<void>.delayed(Duration.zero);
      final counts = await container.read(unreadCountsProvider.future);
      expect(counts.forEvent('evt-123'), 0);
      expect(counts.forGroup('grp-amigos'), 7);
    });

    test('un marcado fallido conserva el feed y no invalida', () async {
      final repository = _CountingActivityLogRepository()..failMark = true;
      var invalidations = 0;
      final notifier = EventActivityNotifier(
        repository: repository,
        eventId: 'evt-123',
        onUnreadCountsChanged: () => invalidations++,
      );
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isSuccess, isTrue);
      expect(repository.readEventIds, ['evt-123']);
      expect(invalidations, 0);
    });

    test('no marca un feed que termina después de dispose', () async {
      final repository = _CountingActivityLogRepository()
        ..pendingFeed = Completer();
      final notifier = EventActivityNotifier(
        repository: repository,
        eventId: 'evt-123',
      );
      notifier.dispose();
      repository.pendingFeed!.complete([]);
      await Future<void>.delayed(Duration.zero);
      expect(repository.readEventIds, isEmpty);
    });
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
  @override
  Future<UnreadCounts> getUnreadCounts() async =>
      UnreadCounts(byEvent: {}, byGroup: {});

  @override
  Future<void> markEventAsRead(String eventId) async {
    readEventIds.add(eventId);
    if (failMark) throw Exception('mark failed');
    if (pendingMark != null) await pendingMark!.future;
  }

  int callCount = 0;
  final readEventIds = <String>[];
  bool failFeed = false;
  bool failMark = false;
  Completer<List<ActivityEntry>>? pendingFeed;
  Completer<void>? pendingMark;

  @override
  Future<List<ActivityEntry>> listEventActivity(String eventId) async {
    callCount++;
    if (failFeed) throw Exception('feed failed');
    if (pendingFeed != null) return pendingFeed!.future;
    return const <ActivityEntry>[];
  }
}
