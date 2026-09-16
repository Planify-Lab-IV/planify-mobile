import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/config/presentation/controllers/schedule_confirmation_notifier.dart';
import 'package:planify/features/events/config/presentation/controllers/schedule_confirmation_state.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/event.dart';
import 'package:planify/features/events/domain/event_status.dart';

void main() {
  const eventId = 'evt-1';

  Event event({EventStatus status = EventStatus.active}) {
    return Event(
      id: eventId,
      name: 'Asado',
      location: 'Casa',
      organizerId: 'org-1',
      groupId: 'grp-1',
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  ScheduleConfirmationNotifier buildNotifier(FakeEventsRepository repository) {
    return ScheduleConfirmationNotifier(repository: repository, eventId: eventId);
  }

  void selectDateAndTime(ScheduleConfirmationNotifier notifier) {
    notifier.selectDate(DateTime(2026, 12, 20));
    notifier.selectTime(const TimeOfDay(hour: 21, minute: 30));
  }

  test('requires a date and time before confirmation is enabled', () async {
    final notifier = buildNotifier(
      FakeEventsRepository(delay: Duration.zero, initialEvents: [event()]),
    );

    expect(notifier.state.canConfirm, isFalse);

    notifier.selectDate(DateTime(2026, 12, 20));
    expect(notifier.state.canConfirm, isFalse);

    notifier.selectTime(const TimeOfDay(hour: 21, minute: 30));
    expect(notifier.state.canConfirm, isTrue);
    expect(notifier.state.startDateTime, DateTime(2026, 12, 20, 21, 30));

    notifier.dispose();
  });

  test('does not call the repository with a partial selection', () async {
    final repository = FakeEventsRepository(
      delay: Duration.zero,
      initialEvents: [event()],
    );
    final notifier = buildNotifier(repository);
    notifier.selectDate(DateTime(2026, 12, 20));

    final success = await notifier.confirmSchedule();

    expect(success, isFalse);
    expect((await repository.getEvent(eventId))?.status, EventStatus.active);
    expect(notifier.state.confirmationStatus, ScheduleConfirmationStatus.idle);

    notifier.dispose();
  });

  test('confirms the selected schedule successfully', () async {
    final repository = FakeEventsRepository(
      delay: Duration.zero,
      initialEvents: [event()],
    );
    final notifier = buildNotifier(repository);
    selectDateAndTime(notifier);

    final success = await notifier.confirmSchedule();

    expect(success, isTrue);
    expect(notifier.state.confirmationSucceeded, isTrue);
    expect((await repository.getEvent(eventId))?.status, EventStatus.confirmed);
    expect(
      (await repository.getEvent(eventId))?.startDateTime,
      DateTime(2026, 12, 20, 21, 30),
    );

    notifier.dispose();
  });

  test('leaves the notifier actionable after a repository failure', () async {
    final notifier = buildNotifier(
      FakeEventsRepository(
        delay: Duration.zero,
        shouldFailScheduleConfirmation: true,
        initialEvents: [event()],
      ),
    );
    selectDateAndTime(notifier);

    final success = await notifier.confirmSchedule();

    expect(success, isFalse);
    expect(notifier.state.confirmationFailed, isTrue);
    expect(notifier.state.failure, ScheduleConfirmationFailure.unknown);
    expect(notifier.state.isConfirming, isFalse);
    expect(notifier.state.canConfirm, isTrue);

    notifier.dispose();
  });

  test('maps a validation failure from the fake', () async {
    final notifier = buildNotifier(
      FakeEventsRepository(delay: Duration.zero, initialEvents: [event()]),
    );
    notifier.selectDate(DateTime(2000, 1, 1));
    notifier.selectTime(const TimeOfDay(hour: 21, minute: 30));

    final success = await notifier.confirmSchedule();

    expect(success, isFalse);
    expect(notifier.state.failure, ScheduleConfirmationFailure.validation);
    expect(notifier.state.isConfirming, isFalse);

    notifier.dispose();
  });
}
