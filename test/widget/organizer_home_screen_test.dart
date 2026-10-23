import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/activity_log/domain/unread_counts.dart';
import 'package:planify/features/activity_log/presentation/controllers/activity_log_providers.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/presentation/controllers/balances_providers.dart';
import 'package:planify/features/events/creation/screens/create_event_step1_screen.dart';
import 'package:planify/features/groups/data/fake_groups_repository.dart';
import 'package:planify/features/groups/data/fake_groups_overview_repository.dart';
import 'package:planify/features/groups/presentation/controllers/groups_providers.dart';
import 'package:planify/features/home/presentation/controllers/registered_home_tab_provider.dart';
import 'package:planify/features/profile/data/fake_profile_repository.dart';
import 'package:planify/features/profile/presentation/controllers/profile_providers.dart';
import 'package:planify/features/home/presentation/screens/organizer_home_screen.dart';
import 'package:planify/features/home/presentation/screens/registered_home_shell.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  group('OrganizerHomeScreen Widget Tests', () {
    const testSession = OrganizerSession(
      userId: 'usr-123',
      email: 'organizador@planify.com',
      name: 'Lucas',
      username: 'lucas',
      token: 'fake-jwt-token',
    );

    Widget buildHomeScreen({
      FakeAuthRepository? fakeAuthRepo,
      FakeSecureStorage? fakeStorage,
      Override? unreadCountsOverride,
      bool withRegisteredShell = false,
    }) {
      final home = OrganizerHomeScreen(session: testSession);
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            fakeAuthRepo ?? FakeAuthRepository(delay: Duration.zero),
          ),
          secureStorageProvider.overrideWithValue(
            fakeStorage ?? FakeSecureStorage(delay: Duration.zero),
          ),
          balancesRepositoryProvider.overrideWithValue(
            FakeBalancesRepository(delay: Duration.zero),
          ),
          profileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(delay: Duration.zero),
          ),
          groupsRepositoryProvider.overrideWithValue(
            FakeGroupsRepository(delay: Duration.zero),
          ),
          groupsOverviewRepositoryProvider.overrideWithValue(
            FakeGroupsOverviewRepository(delay: Duration.zero),
          ),
          unreadCountsOverride ??
              unreadCountsProvider.overrideWith(
                (ref) => Future.value(
                  UnreadCounts(byEvent: const {}, byGroup: const {}),
                ),
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
          home: withRegisteredShell ? RegisteredHomeShell(home: home) : home,
        ),
      );
    }

    testWidgets(
      'renderiza boton Crear nuevo evento y navega al wizard Paso 1',
      (tester) async {
        await tester.pumpWidget(buildHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('create_event_button')), findsOneWidget);
        expect(find.text('Crear nuevo evento'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('create_event_button')),
        );
        await tester.tap(find.byKey(const Key('create_event_button')));
        await tester.pumpAndSettle();

        expect(find.byType(CreateEventStep1Screen), findsOneWidget);
        expect(find.text('Información básica'), findsOneWidget);
      },
    );

    testWidgets('muestra la campana y selecciona Grupos al tocarla', (
      tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen(withRegisteredShell: true));
      await tester.pump();
      await tester.pump();

      final notificationsButton = find.byKey(
        const Key('home_notifications_button'),
      );
      expect(notificationsButton, findsOneWidget);
      expect(
        tester.widget<IconButton>(notificationsButton).tooltip,
        'Ver novedades',
      );
      expect(
        find.descendant(
          of: notificationsButton,
          matching: find.byIcon(Icons.notifications_outlined),
        ),
        findsOneWidget,
      );

      await tester.tap(notificationsButton);
      await tester.pump();

      expect(
        tester
            .widget<NavigationBar>(
              find.byKey(const Key('registered_navigation_bar')),
            )
            .selectedIndex,
        registeredHomeGroupsTabIndex,
      );
      expect(find.byKey(const Key('group_avatar_grp-amigos')), findsOneWidget);
    });

    testWidgets('muestra el punto cuando hay novedades sin leer', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHomeScreen(
          unreadCountsOverride: unreadCountsProvider.overrideWith(
            (ref) => Future.value(
              UnreadCounts(byEvent: {'evt-123': 1}, byGroup: {}),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_notifications_dot')), findsOneWidget);
    });

    testWidgets('oculta el punto cuando no hay novedades sin leer', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHomeScreen(
          unreadCountsOverride: unreadCountsProvider.overrideWith(
            (ref) => Future.value(
              UnreadCounts(byEvent: {'evt-123': 0}, byGroup: {}),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_notifications_dot')), findsNothing);
    });

    testWidgets('oculta el punto mientras cargan los contadores', (
      tester,
    ) async {
      final pendingCounts = Completer<UnreadCounts>();
      await tester.pumpWidget(
        buildHomeScreen(
          unreadCountsOverride: unreadCountsProvider.overrideWith(
            (ref) => pendingCounts.future,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(
        find.byKey(const Key('home_notifications_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home_notifications_dot')), findsNothing);
    });

    testWidgets('oculta el punto si falla la consulta de contadores', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHomeScreen(
          unreadCountsOverride: unreadCountsProvider.overrideWith(
            (ref) => Future<UnreadCounts>.error(StateError('network error')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('home_notifications_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home_notifications_dot')), findsNothing);
    });
  });
}
