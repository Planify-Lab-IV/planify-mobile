import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/widgets/planify_logo.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/presentation/controllers/activity_log_providers.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/main.dart';
import 'package:planify/features/events/data/events_repository_provider.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/home/presentation/screens/registered_home_shell.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';

void main() {
  testWidgets('la app inicia sin Firebase en plataformas fuera de Android', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(delay: Duration.zero),
            ),
            secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(PlanifyLogo), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  for (final anonymous in [false, true]) {
    testWidgets(
      anonymous
          ? 'anonymous session has no bottom navigation'
          : 'registered session has all four destinations',
      (tester) async {
        final storage = FakeSecureStorage();
        final repository = FakeAuthRepository(
          storage: storage,
          delay: Duration.zero,
        );
        if (anonymous) {
          await repository.loginAnonymously(
            name: 'Guest',
            pin: '1234',
            eventId: 'evt-123',
          );
        } else {
          await repository.login(
            identifier: 'lucas@example.com',
            password: '123456',
          );
        }
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activityLogRepositoryProvider.overrideWithValue(
                FakeActivityLogRepository(delay: Duration.zero),
              ),
              authRepositoryProvider.overrideWithValue(repository),
              secureStorageProvider.overrideWithValue(storage),
              eventsRepositoryProvider.overrideWithValue(
                FakeEventsRepository(delay: Duration.zero),
              ),
            ],
            child: const MyApp(startPushRegistration: false),
          ),
        );
        await tester.pumpAndSettle();
        if (anonymous) {
          expect(find.byType(ParticipantHomeScreen), findsOneWidget);
          expect(find.byType(NavigationBar), findsNothing);
        } else {
          expect(find.byType(RegisteredHomeShell), findsOneWidget);
          expect(find.byType(NavigationDestination), findsNWidgets(4));
        }
      },
    );
  }
  testWidgets('Smoke test de inicio de la aplicación Planify', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(delay: Duration.zero),
          ),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localeNotifierProvider.overrideWith(
            (ref) => LocaleNotifier()..setLocale(const Locale('es')),
          ),
        ],
        child: const MyApp(startPushRegistration: false),
      ),
    );

    // SplashScreen es estática: pumpAndSettle no espera el timer del fake storage.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byType(PlanifyLogo), findsOneWidget);
    expect(find.text('Planify'), findsOneWidget);
    expect(find.text('Organizá tus planes, sin vueltas'), findsOneWidget);
  });
}
