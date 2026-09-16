import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/controllers/event_detail_notifier.dart';
import 'package:planify/features/events/detail/controllers/events_providers.dart';
import 'package:planify/features/events/detail/screens/event_detail_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  testWidgets('muestra un error de carga genérico y permite reintentar', (
    tester,
  ) async {
    final repository = FakeEventsRepository(
      delay: Duration.zero,
      shouldThrowError: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventDetailNotifierProvider('evt-1').overrideWith((ref) {
            return EventDetailNotifier(
              repository: repository,
              currentSession: const OrganizerSession(
                userId: 'org-1',
                email: 'organizer@planify.com',
                name: 'Organizer',
                username: 'organizer',
                token: 'token',
              ),
              eventId: 'evt-1',
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: const EventDetailScreen(eventId: 'evt-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No se pudo cargar el evento. Verificá tu conexión e intentá nuevamente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Evento no encontrado'), findsNothing);
    expect(find.byKey(const Key('retry_load_event_button')), findsOneWidget);
  });
}
