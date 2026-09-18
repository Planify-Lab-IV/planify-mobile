import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/event_exceptions.dart';
import '../../../domain/events_repository.dart';
import 'schedule_confirmation_state.dart';

class ScheduleConfirmationNotifier
    extends StateNotifier<ScheduleConfirmationState> {
  final EventsRepository repository;
  final String eventId;

  ScheduleConfirmationNotifier({
    required this.repository,
    required this.eventId,
  }) : super(const ScheduleConfirmationState());

  void setInitialStartDateTime(DateTime? startDateTime) {
    if (startDateTime == null ||
        state.selectedDate != null ||
        state.selectedTime != null ||
        state.isConfirming) {
      return;
    }

    final localStartDateTime = startDateTime.toLocal();
    state = state.copyWith(
      selectedDate: DateTime(
        localStartDateTime.year,
        localStartDateTime.month,
        localStartDateTime.day,
      ),
      selectedTime: TimeOfDay.fromDateTime(localStartDateTime),
    );
  }

  void selectDate(DateTime date) {
    if (state.isConfirming) return;

    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
      confirmationStatus: ScheduleConfirmationStatus.idle,
      clearFailure: true,
    );
  }

  void selectTime(TimeOfDay time) {
    if (state.isConfirming) return;

    state = state.copyWith(
      selectedTime: time,
      confirmationStatus: ScheduleConfirmationStatus.idle,
      clearFailure: true,
    );
  }

  Future<bool> confirmSchedule() async {
    final startDateTime = state.startDateTime;
    if (startDateTime == null || state.isConfirming) return false;

    state = state.copyWith(
      confirmationStatus: ScheduleConfirmationStatus.inProgress,
      clearFailure: true,
    );

    try {
      await repository.confirmSchedule(eventId, startDateTime);
      if (!mounted) return false;

      state = state.copyWith(
        confirmationStatus: ScheduleConfirmationStatus.success,
      );
      return true;
    } on EventScheduleValidationException {
      return _setFailure(ScheduleConfirmationFailure.validation);
    } on EventScheduleAuthorizationException {
      return _setFailure(ScheduleConfirmationFailure.authorization);
    } on EventNotFoundException {
      return _setFailure(ScheduleConfirmationFailure.notFound);
    } on NetworkEventException {
      return _setFailure(ScheduleConfirmationFailure.network);
    } on EventsException {
      return _setFailure(ScheduleConfirmationFailure.unknown);
    } catch (_) {
      return _setFailure(ScheduleConfirmationFailure.unknown);
    }
  }

  bool _setFailure(ScheduleConfirmationFailure failure) {
    if (!mounted) return false;

    state = state.copyWith(
      confirmationStatus: ScheduleConfirmationStatus.failure,
      failure: failure,
    );
    return false;
  }
}
