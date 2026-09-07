import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/config/presentation/screens/event_config_screen.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/controllers/events_providers.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  const eventId = 'evt-123';

  Widget buildScreen(FakeEventsRepository repository) {
    return ProviderScope(
      overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
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
        home: const EventConfigScreen(eventId: eventId),
      ),
    );
  }

  testWidgets('muestra y actualiza la asistencia en Event Config', (
    tester,
  ) async {
    final repository = FakeEventsRepository(delay: Duration.zero);

    await tester.pumpWidget(buildScreen(repository));
    await tester.pump();
    await tester.pump();

    expect(find.text('Configuración del evento'), findsOneWidget);
    expect(find.byKey(const Key('attendance_response_selector')), findsOneWidget);

    await tester.tap(find.byKey(const Key('attendance_confirm_button')));
    await tester.pump();
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Voy'), findsOneWidget);
  });
}
