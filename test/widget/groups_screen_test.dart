import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/widgets/unread_badge.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/domain/unread_counts.dart';
import 'package:planify/features/activity_log/presentation/controllers/activity_log_providers.dart';
import 'package:planify/features/debts/data/fake_debts_repository.dart';
import 'package:planify/features/debts/presentation/controllers/debts_providers.dart';
import 'package:planify/features/events/data/events_repository_provider.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/screens/event_detail_screen.dart';
import 'package:planify/features/events/domain/event_status.dart';
import 'package:planify/features/groups/data/fake_groups_overview_repository.dart';
import 'package:planify/features/groups/domain/group_overview.dart';
import 'package:planify/features/groups/domain/groups_overview_repository.dart';
import 'package:planify/features/groups/presentation/controllers/groups_providers.dart';
import 'package:planify/features/groups/presentation/screens/groups_screen.dart';
import 'package:planify/features/tasks/data/fake_tasks_repository.dart';
import 'package:planify/features/tasks/presentation/controllers/tasks_providers.dart';
import 'package:planify/l10n/app_localizations.dart';

class MutableOverviewRepository implements GroupsOverviewRepository {
  List<GroupOverview> groups;
  bool fail = false;
  int calls = 0;
  Completer<List<GroupOverview>>? pending;
  MutableOverviewRepository(this.groups);
  @override
  Future<List<GroupOverview>> getMyGroupsOverview() async {
    calls++;
    if (pending != null) return pending!.future;
    if (fail) throw Exception('failure');
    return groups;
  }
}

Widget app(
  GroupsOverviewRepository repository, {
  String language = 'es',
  FakeActivityLogRepository? activityRepository,
}) => ProviderScope(
  overrides: [
    activityLogRepositoryProvider.overrideWithValue(
      activityRepository ?? FakeActivityLogRepository(delay: Duration.zero),
    ),
    groupsOverviewRepositoryProvider.overrideWithValue(repository),
    eventsRepositoryProvider.overrideWithValue(
      FakeEventsRepository(delay: Duration.zero),
    ),
    debtsRepositoryProvider.overrideWithValue(
      FakeDebtsRepository(delay: Duration.zero),
    ),
    tasksRepositoryProvider.overrideWithValue(
      FakeTasksRepository(delay: Duration.zero),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const GroupsScreen(),
  ),
);

void main() {
  String badgeText(WidgetTester tester, String key) => tester
      .widget<Text>(
        find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
      )
      .data!;

  testWidgets('usa los conteos de grupo recibidos sin sumar eventos', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        FakeGroupsOverviewRepository(delay: Duration.zero),
        activityRepository: FakeActivityLogRepository(
          delay: Duration.zero,
          initialUnreadCounts: UnreadCounts(
            byEvent: {'evt-123': 2},
            byGroup: {'grp-amigos': 15},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(badgeText(tester, 'group_unread_badge_grp-amigos'), '9+');
    expect(badgeText(tester, 'event_unread_badge_evt-123'), '2');
    expect(
      find.byKey(const Key('group_unread_badge_grp-trabajo')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('event_unread_badge_evt-fake-demo')),
      findsNothing,
    );
  });

  testWidgets(
    'al volver del feed actualiza el evento y su grupo sin refrescar',
    (tester) async {
      final overview = MutableOverviewRepository(
        await FakeGroupsOverviewRepository(
          delay: Duration.zero,
        ).getMyGroupsOverview(),
      );
      final activity = FakeActivityLogRepository(delay: Duration.zero);
      await tester.pumpWidget(app(overview, activityRepository: activity));
      await tester.pumpAndSettle();
      expect(badgeText(tester, 'group_unread_badge_grp-amigos'), '9+');
      expect(badgeText(tester, 'event_unread_badge_evt-123'), '5');
      await tester.tap(find.byKey(const Key('group_event_tile_evt-123')));
      await tester.pumpAndSettle();
      expect((await activity.getUnreadCounts()).forEvent('evt-123'), 0);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event_unread_badge_evt-123')), findsNothing);
      expect(badgeText(tester, 'group_unread_badge_grp-amigos'), '7');
      expect(badgeText(tester, 'event_unread_badge_evt-asado-amigos'), '7');
      expect(overview.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final failFeed in [true, false]) {
    testWidgets(
      'un fallo de ${failFeed ? 'feed' : 'marcado'} conserva los contadores y la navegación',
      (tester) async {
        final activity = FakeActivityLogRepository(
          delay: Duration.zero,
          shouldThrowError: failFeed,
          shouldThrowMarkAsReadError: !failFeed,
        );
        await tester.pumpWidget(
          app(
            FakeGroupsOverviewRepository(delay: Duration.zero),
            activityRepository: activity,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('group_event_tile_evt-123')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('event_activity_error')),
          failFeed ? findsOneWidget : findsNothing,
        );
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();
        expect(badgeText(tester, 'event_unread_badge_evt-123'), '5');
        expect(badgeText(tester, 'group_unread_badge_grp-amigos'), '9+');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('el error de contadores oculta badges sin bloquear la lista', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        FakeGroupsOverviewRepository(delay: Duration.zero),
        activityRepository: FakeActivityLogRepository(
          delay: Duration.zero,
          shouldThrowUnreadCountsError: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(UnreadBadge), findsNothing);
    expect(find.byKey(const Key('group_event_tile_evt-123')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('groups_screen_error')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'durante carga de contadores muestra la lista sin badges ni spinner',
    (tester) async {
      await tester.pumpWidget(
        app(
          FakeGroupsOverviewRepository(delay: Duration.zero),
          activityRepository: FakeActivityLogRepository(
            delay: const Duration(seconds: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('group_event_tile_evt-123')), findsOneWidget);
      expect(find.byType(UnreadBadge), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('loading then empty groups are rendered', (tester) async {
    final repo = MutableOverviewRepository([])..pending = Completer();
    await tester.pumpWidget(app(repo));
    expect(find.byKey(const Key('groups_screen_loading')), findsOneWidget);
    repo.pending!.complete([]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('groups_screen_empty')), findsOneWidget);
  });

  testWidgets('error can be retried successfully', (tester) async {
    final repo = MutableOverviewRepository([])..fail = true;
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('groups_screen_error')), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.byKey(const Key('groups_screen_retry_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('groups_screen_empty')), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets(
    'selection preserves order and changes events without loading again',
    (tester) async {
      final groups = await FakeGroupsOverviewRepository(
        delay: Duration.zero,
      ).getMyGroupsOverview();
      final repo = MutableOverviewRepository(groups);
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group_event_tile_evt-123')), findsOneWidget);
      expect(find.text('A definir'), findsWidgets);
      await tester.tap(find.byKey(const Key('group_avatar_grp-familia')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('group_event_tile_evt-almuerzo-familia')),
        findsOneWidget,
      );
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
      expect(repo.calls, 1);
      await tester.tap(find.byKey(const Key('group_avatar_grp-trabajo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group_events_empty')), findsOneWidget);
    },
  );

  testWidgets('pull to refresh falls back when selected group disappears', (
    tester,
  ) async {
    final groups = await FakeGroupsOverviewRepository(
      delay: Duration.zero,
    ).getMyGroupsOverview();
    final repo = MutableOverviewRepository(groups);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_avatar_grp-familia')));
    await tester.pumpAndSettle();
    repo.groups = [groups.first];
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(find.byKey(const Key('group_event_tile_evt-123')), findsOneWidget);
  });

  testWidgets('event tap sends correct ID to detail', (tester) async {
    await tester.pumpWidget(
      app(FakeGroupsOverviewRepository(delay: Duration.zero)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_event_tile_evt-123')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EventDetailScreen>(find.byType(EventDetailScreen)).eventId,
      'evt-123',
    );
    expect(find.byKey(const Key('event_activity_card')), findsOneWidget);
    expect(find.byKey(const Key('event_activity_loading')), findsNothing);
  });

  testWidgets('English copy and cancelled-event exclusion', (tester) async {
    final group = GroupOverview(
      id: 'g',
      name: 'Group',
      memberCount: 1,
      events: const [
        GroupEventSummary(
          id: 'cancelled',
          name: 'Cancelled event',
          status: EventStatus.cancelled,
          location: 'Place',
        ),
        GroupEventSummary(
          id: 'active',
          name: 'Active event',
          status: EventStatus.active,
          location: 'Place',
        ),
      ],
    );
    await tester.pumpWidget(
      app(
        FakeGroupsOverviewRepository(
          delay: Duration.zero,
          initialGroups: [group],
        ),
        language: 'en',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('1 member'), findsOneWidget);
    expect(find.text('TBD'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byKey(const Key('group_event_tile_cancelled')), findsNothing);
  });
}
