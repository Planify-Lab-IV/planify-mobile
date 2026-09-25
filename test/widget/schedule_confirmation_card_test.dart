import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/config/presentation/controllers/schedule_confirmation_providers.dart';
import 'package:planify/features/events/config/presentation/widgets/schedule_confirmation_card.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/controllers/events_providers.dart';
import 'package:planify/features/events/domain/event.dart';
import 'package:planify/features/events/domain/event_status.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  const eventId = 'evt-1';

  Event event() {
    return Event(
      id: eventId,
      name: 'Asado',
      location: 'Casa',
      organizerId: 'org-1',
      groupId: 'grp-1',
      status: EventStatus.active,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    ProviderContainer container, {
    DateTime? initialStartDateTime,
    Future<void> Function()? onConfirmationSucceeded,
  }) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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
          home: Scaffold(
            body: ScheduleConfirmationCard(
              eventId: eventId,
              initialStartDateTime: initialStartDateTime,
              onConfirmationSucceeded: onConfirmationSucceeded ?? () async {},
            ),
          ),
        ),
      ),
    );
  }

  void selectDateAndTime(ProviderContainer container) {
    final notifier = container.read(
      scheduleConfirmationNotifierProvider(eventId).notifier,
    );
    notifier.selectDate(DateTime(2026, 12, 20));
    notifier.selectTime(const TimeOfDay(hour: 21, minute: 30));
  }

  testWidgets(
    'keeps the confirmation button disabled until date and time are selected',
    (tester) async {
      final repository = FakeEventsRepository(
        delay: Duration.zero,
        initialEvents: [event()],
      );
      final container = ProviderContainer(
        overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await pumpCard(tester, container);
      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('schedule_confirm_button')),
      );
      expect(button.onPressed, isNull);

      container
          .read(scheduleConfirmationNotifierProvider(eventId).notifier)
          .selectDate(DateTime(2026, 12, 20));
      await tester.pump();
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('schedule_confirm_button')),
            )
            .onPressed,
        isNull,
      );

      selectDateAndTime(container);
      await tester.pump();
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('schedule_confirm_button')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('initializes the selected date and time after the first frame', (
    tester,
  ) async {
    final repository = FakeEventsRepository(
      delay: Duration.zero,
      initialEvents: [event()],
    );
    final container = ProviderContainer(
      overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await pumpCard(
      tester,
      container,
      initialStartDateTime: DateTime(2026, 12, 20, 21, 30),
    );
    await tester.pump();

    final state = container.read(scheduleConfirmationNotifierProvider(eventId));
    expect(state.selectedDate, DateTime(2026, 12, 20));
    expect(state.selectedTime, const TimeOfDay(hour: 21, minute: 30));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opens the date picker from today for a past confirmed schedule',
    (tester) async {
      final repository = FakeEventsRepository(
        delay: Duration.zero,
        initialEvents: [event()],
      );
      final container = ProviderContainer(
        overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await pumpCard(
        tester,
        container,
        initialStartDateTime: DateTime.now().subtract(const Duration(days: 1)),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('schedule_select_date_button')));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('confirms the selected schedule successfully', (tester) async {
    final repository = FakeEventsRepository(
      delay: Duration.zero,
      initialEvents: [event()],
    );
    final container = ProviderContainer(
      overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await pumpCard(tester, container);
    selectDateAndTime(container);
    await tester.pump();

    await tester.tap(find.byKey(const Key('schedule_confirm_button')));
    await tester.pump();

    final confirmedEvent = await repository.getEvent(eventId);
    expect(confirmedEvent?.status, EventStatus.confirmed);
    expect(confirmedEvent?.startDateTime, DateTime(2026, 12, 20, 21, 30));
  });

  testWidgets('refreshes the event before showing the confirmation message', (
    tester,
  ) async {
    final repository = FakeEventsRepository(
      delay: Duration.zero,
      initialEvents: [event()],
    );
    final container = ProviderContainer(
      overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final refreshCompleter = Completer<void>();
    var didRefreshEvent = false;

    await pumpCard(
      tester,
      container,
      onConfirmationSucceeded: () async {
        didRefreshEvent = true;
        await refreshCompleter.future;
      },
    );
    selectDateAndTime(container);
    await tester.pump();

    await tester.tap(find.byKey(const Key('schedule_confirm_button')));
    await tester.pump();

    expect(didRefreshEvent, isTrue);
    expect(
      find.byKey(const Key('schedule_confirmation_success_snackbar')),
      findsNothing,
    );

    refreshCompleter.complete();
    await tester.pump();

    expect(
      find.byKey(const Key('schedule_confirmation_success_snackbar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a clear error and re-enables the button after a failure', (
    tester,
  ) async {
    final repository = FakeEventsRepository(
      delay: Duration.zero,
      shouldFailScheduleConfirmation: true,
      initialEvents: [event()],
    );
    final container = ProviderContainer(
      overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await pumpCard(tester, container);
    selectDateAndTime(container);
    await tester.pump();

    await tester.tap(find.byKey(const Key('schedule_confirm_button')));
    await tester.pump();

    expect(
      find.byKey(const Key('schedule_confirmation_error_message')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('schedule_confirm_button')),
          )
          .onPressed,
      isNotNull,
    );
  });
}
