import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/presentation/controllers/balances_providers.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';
import 'package:planify/features/home/presentation/screens/registered_home_shell.dart';
import 'package:planify/main.dart';

void main() {
  Future<AuthNotifier> authenticatedNotifier(UserSession session) async {
    final storage = FakeSecureStorage();
    final repository = FakeAuthRepository(
      storage: storage,
      delay: Duration.zero,
    );
    final notifier = AuthNotifier(repository, storage);

    switch (session) {
      case OrganizerSession():
        await notifier.login(
          identifier: session.email,
          password: 'password123',
        );
      case AnonymousSession():
        await notifier.loginAnonymously(
          name: session.name,
          pin: '1234',
          eventId: session.eventId,
        );
    }

    return notifier;
  }

  Widget appWithSession(AuthNotifier notifier) {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => notifier),
        balancesRepositoryProvider.overrideWithValue(
          FakeBalancesRepository(delay: Duration.zero),
        ),
        localeNotifierProvider.overrideWith(
          (ref) => LocaleNotifier()..setLocale(const Locale('es')),
        ),
      ],
      child: const MyApp(),
    );
  }

  testWidgets('a registered session reaches Balances from the bottom bar', (
    tester,
  ) async {
    final notifier = await authenticatedNotifier(
      const OrganizerSession(
        userId: 'user-1',
        name: 'dev1',
        email: 'dev1@planify.dev',
        username: 'dev1',
        token: 'registered-token',
      ),
    );
    await tester.pumpWidget(appWithSession(notifier));
    await tester.pumpAndSettle();

    expect(find.byType(RegisteredHomeShell), findsOneWidget);
    expect(find.byKey(const Key('registered_navigation_bar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('registered_navigation_balances')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('balance_summary_card')), findsOneWidget);
  });

  testWidgets('an anonymous session does not expose the Balances navigation', (
    tester,
  ) async {
    final notifier = await authenticatedNotifier(
      const AnonymousSession(
        participantId: 'participant-1',
        name: 'Invitado',
        eventId: 'event-1',
        token: 'anonymous-token',
      ),
    );
    await tester.pumpWidget(appWithSession(notifier));
    await tester.pumpAndSettle();

    expect(find.byType(ParticipantHomeScreen), findsOneWidget);
    expect(find.byType(RegisteredHomeShell), findsNothing);
    expect(find.byKey(const Key('registered_navigation_bar')), findsNothing);
    expect(
      find.byKey(const Key('registered_navigation_balances')),
      findsNothing,
    );
  });
}
