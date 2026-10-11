import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/presentation/controllers/balances_providers.dart';
import 'package:planify/features/home/presentation/screens/registered_home_shell.dart';
import 'package:planify/l10n/app_localizations.dart';
import 'package:planify/features/groups/data/fake_groups_overview_repository.dart';
import 'package:planify/features/groups/presentation/controllers/groups_providers.dart';
import 'package:planify/features/groups/domain/group_overview.dart';
import 'package:planify/features/events/domain/event_status.dart';

void main() {
  testWidgets('groups scroll and repository state survive tab changes', (
    tester,
  ) async {
    final groups = [
      GroupOverview(
        id: 'long',
        name: 'Long group',
        memberCount: 2,
        events: [
          for (var i = 0; i < 20; i++)
            GroupEventSummary(
              id: 'event-$i',
              name: 'Event $i',
              status: EventStatus.active,
              location: 'Place',
            ),
        ],
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsOverviewRepositoryProvider.overrideWithValue(
            FakeGroupsOverviewRepository(
              delay: Duration.zero,
              initialGroups: groups,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const RegisteredHomeShell(home: Scaffold(body: Text('Home'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('registered_navigation_groups')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    final before = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(before, greaterThan(0));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RegisteredHomeShell)),
    );
    final beforeOverview = container.read(groupsOverviewProvider);
    await tester.tap(find.byKey(const Key('registered_navigation_home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('registered_navigation_groups')));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels, before);
    expect(
      identical(container.read(groupsOverviewProvider), beforeOverview),
      isTrue,
    );
  });
  testWidgets('la shell registrada permite alternar entre Inicio y Balances', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsOverviewRepositoryProvider.overrideWithValue(
            FakeGroupsOverviewRepository(delay: Duration.zero),
          ),
          balancesRepositoryProvider.overrideWithValue(
            FakeBalancesRepository(delay: Duration.zero),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: const RegisteredHomeShell(
            home: Scaffold(body: Center(child: Text('Inicio de prueba'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('registered_navigation_bar')), findsOneWidget);
    expect(find.text('Inicio de prueba'), findsOneWidget);
    expect(find.text('Balances'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    await tester.tap(find.byKey(const Key('registered_navigation_groups')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_avatar_grp-familia')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('group_event_tile_evt-almuerzo-familia')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('registered_navigation_home')));
    await tester.pumpAndSettle();
    expect(find.text('Inicio de prueba'), findsOneWidget);
    await tester.tap(find.byKey(const Key('registered_navigation_groups')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('group_event_tile_evt-almuerzo-familia')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('registered_navigation_balances')));
    await tester.pumpAndSettle();

    expect(find.text('Saldos por persona'), findsOneWidget);
    expect(find.byKey(const Key('balance_summary_card')), findsOneWidget);
  });
}
