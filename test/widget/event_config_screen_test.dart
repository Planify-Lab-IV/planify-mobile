import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/availability/data/fake_availability_repository.dart';
import 'package:planify/features/availability/domain/slot.dart';
import 'package:planify/features/availability/presentation/controllers/availability_providers.dart';
import 'package:planify/features/availability/presentation/widgets/availability_grid.dart';
import 'package:planify/features/events/config/presentation/screens/event_config_screen.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/controllers/events_providers.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  const eventId = 'evt-123';

  Widget buildScreen(
    FakeEventsRepository repository, {
    FakeAvailabilityRepository? availabilityRepository,
  }) {
    return ProviderScope(
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repository),
        availabilityRepositoryProvider.overrideWithValue(
          availabilityRepository ??
              FakeAvailabilityRepository(delay: Duration.zero),
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
    expect(
      find.byKey(const Key('attendance_response_selector')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('attendance_confirm_button')));
    await tester.pump();
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Voy'), findsOneWidget);
  });

  testWidgets('precarga y guarda la disponibilidad completa', (tester) async {
    final availabilityRepository = FakeAvailabilityRepository(
      delay: Duration.zero,
      initialAvailabilityByEvent: {
        eventId: [Slot(dayOfWeek: 0, hour: 0)],
      },
    );

    await tester.pumpWidget(
      buildScreen(
        FakeEventsRepository(delay: Duration.zero),
        availabilityRepository: availabilityRepository,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('availability_grid')), findsOneWidget);
    await tester.tap(find.byKey(const Key('availability_slot_1_0')));
    final saveButton = find.byKey(const Key('availability_save_button'));
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump();

    expect(
      await availabilityRepository.load(eventId),
      unorderedEquals([
        Slot(dayOfWeek: 0, hour: 0),
        Slot(dayOfWeek: 1, hour: 0),
      ]),
    );
  });

  testWidgets('bloquea la grilla mientras se guarda la disponibilidad', (
    tester,
  ) async {
    final availabilityRepository = FakeAvailabilityRepository(
      delay: const Duration(seconds: 1),
    );

    await tester.pumpWidget(
      buildScreen(
        FakeEventsRepository(delay: Duration.zero),
        availabilityRepository: availabilityRepository,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    await tester.tap(find.byKey(const Key('availability_slot_1_0')));
    final saveButton = find.byKey(const Key('availability_save_button'));
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveButton);
    await tester.pump();

    final availabilityGrid = tester.widget<AvailabilityGrid>(
      find.byType(AvailabilityGrid),
    );
    expect(availabilityGrid.isEnabled, isFalse);

    await tester.pump(const Duration(seconds: 1));
  });
}
