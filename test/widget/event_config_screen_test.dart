import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/availability/data/fake_availability_repository.dart';
import 'package:planify/features/availability/domain/availability_heatmap_dto.dart';
import 'package:planify/features/availability/domain/slot.dart';
import 'package:planify/features/availability/presentation/controllers/availability_providers.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/availability/presentation/widgets/availability_grid.dart';
import 'package:planify/features/events/config/presentation/screens/event_config_screen.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/controllers/event_detail_notifier.dart';
import 'package:planify/features/events/detail/controllers/events_providers.dart';
import 'package:planify/l10n/app_localizations.dart';

class TrackingAvailabilityRepository extends FakeAvailabilityRepository {
  int heatmapCalls = 0;

  TrackingAvailabilityRepository({super.delay});

  @override
  Future<AvailabilityHeatmapDto> heatmap(String eventId) {
    heatmapCalls++;
    return super.heatmap(eventId);
  }
}

void main() {
  const eventId = 'evt-123';
  const organizerSession = OrganizerSession(
    userId: 'org-123',
    email: 'organizer@planify.com',
    name: 'Organizador',
    username: 'organizador',
    token: 'organizer-token',
  );

  Widget buildScreen(
    FakeEventsRepository repository, {
    FakeAvailabilityRepository? availabilityRepository,
    UserSession? session,
  }) {
    final resolvedAvailabilityRepository =
        availabilityRepository ??
        FakeAvailabilityRepository(delay: Duration.zero);

    return ProviderScope(
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repository),
        availabilityRepositoryProvider.overrideWithValue(
          resolvedAvailabilityRepository,
        ),
        availabilityHeatmapRepositoryProvider.overrideWithValue(
          resolvedAvailabilityRepository,
        ),
        eventDetailNotifierProvider(eventId).overrideWith((ref) {
          return EventDetailNotifier(
            repository: repository,
            currentSession: session,
            eventId: eventId,
          );
        }),
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
        eventId: [Slot(weekDay: 0, hourBlock: 0)],
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
        Slot(weekDay: 0, hourBlock: 0),
        Slot(weekDay: 1, hourBlock: 0),
      ]),
    );
  });

  testWidgets('muestra y carga el heatmap combinado para el organizador', (
    tester,
  ) async {
    final availabilityRepository = TrackingAvailabilityRepository(
      delay: Duration.zero,
    );

    await tester.pumpWidget(
      buildScreen(
        FakeEventsRepository(delay: Duration.zero),
        availabilityRepository: availabilityRepository,
        session: organizerSession,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Disponibilidad combinada'), findsOneWidget);
    expect(find.byKey(const Key('availability_heatmap_grid')), findsOneWidget);
    expect(availabilityRepository.heatmapCalls, 1);
  });

  testWidgets('oculta y no carga el heatmap para un participante', (
    tester,
  ) async {
    final availabilityRepository = TrackingAvailabilityRepository(
      delay: Duration.zero,
    );

    await tester.pumpWidget(
      buildScreen(
        FakeEventsRepository(delay: Duration.zero),
        availabilityRepository: availabilityRepository,
        session: const OrganizerSession(
          userId: 'participant-123',
          email: 'participant@planify.com',
          name: 'Participante',
          username: 'participante',
          token: 'participant-token',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Disponibilidad combinada'), findsNothing);
    expect(find.byKey(const Key('availability_heatmap_grid')), findsNothing);
    expect(availabilityRepository.heatmapCalls, 0);
  });

  testWidgets('oculta y no carga el heatmap para un usuario anónimo', (
    tester,
  ) async {
    final availabilityRepository = TrackingAvailabilityRepository(
      delay: Duration.zero,
    );

    await tester.pumpWidget(
      buildScreen(
        FakeEventsRepository(delay: Duration.zero),
        availabilityRepository: availabilityRepository,
        session: const AnonymousSession(
          participantId: 'anonymous-123',
          name: 'Anónimo',
          eventId: eventId,
          token: 'anonymous-token',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Disponibilidad combinada'), findsNothing);
    expect(find.byKey(const Key('availability_heatmap_grid')), findsNothing);
    expect(availabilityRepository.heatmapCalls, 0);
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
