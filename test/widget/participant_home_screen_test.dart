import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/event.dart';
import 'package:planify/features/events/domain/event_status.dart';
import 'package:planify/features/events/detail/controllers/events_providers.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  const eventId = 'evt-123';
  const session = AnonymousSession(
    participantId: 'participant-123',
    name: 'Lu',
    eventId: eventId,
    token: 'fake-token',
  );

  final activeEvent = Event(
    id: eventId,
    name: 'Test participant',
    location: 'Casa',
    organizerId: 'organizer-123',
    groupId: 'group-123',
    status: EventStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Widget buildHome(FakeEventsRepository repository) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(delay: Duration.zero),
        ),
        secureStorageProvider.overrideWithValue(FakeSecureStorage()),
        eventsRepositoryProvider.overrideWithValue(repository),
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
        home: const ParticipantHomeScreen(session: session),
      ),
    );
  }

  testWidgets(
    'recarga el detalle al volver a abrir un evento cancelado externamente',
    (tester) async {
      final repository = FakeEventsRepository(
        delay: Duration.zero,
        initialEvents: [activeEvent],
      );

      await tester.pumpWidget(buildHome(repository));
      await tester.pumpAndSettle();

      await repository.cancel(eventId);

      await tester.tap(find.byKey(const Key('view_event_detail_button')));
      await tester.pumpAndSettle();

      expect(find.text('Cancelado'), findsOneWidget);
      expect(find.byKey(const Key('event_config_button')), findsNothing);
    },
  );
}
