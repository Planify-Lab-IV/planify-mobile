import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/creation/controllers/event_draft_providers.dart';
import 'package:planify/features/events/creation/screens/create_event_step1_screen.dart';
import 'package:planify/features/groups/data/fake_groups_repository.dart';
import 'package:planify/features/groups/presentation/controllers/groups_providers.dart';
import 'package:planify/features/home/presentation/screens/organizer_home_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  group('OrganizerHomeScreen Widget Tests', () {
    const testSession = OrganizerSession(
      userId: 'usr-123',
      email: 'organizador@planify.com',
      name: 'Lucas',
      token: 'fake-jwt-token',
    );

    Widget buildHomeScreen({
      FakeAuthRepository? fakeAuthRepo,
      FakeSecureStorage? fakeStorage,
    }) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            fakeAuthRepo ?? FakeAuthRepository(delay: Duration.zero),
          ),
          secureStorageProvider.overrideWithValue(
            fakeStorage ?? FakeSecureStorage(),
          ),
          groupsRepositoryProvider.overrideWithValue(
            FakeGroupsRepository(delay: Duration.zero),
          ),
          eventsRepositoryProvider.overrideWithValue(
            FakeEventsRepository(delay: Duration.zero),
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
          home: const OrganizerHomeScreen(session: testSession),
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
  });
}
