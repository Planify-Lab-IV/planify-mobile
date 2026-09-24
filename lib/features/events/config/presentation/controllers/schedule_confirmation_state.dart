import 'package:flutter/material.dart';

enum ScheduleConfirmationStatus { idle, inProgress, success, failure }

enum ScheduleConfirmationFailure {
  validation,
  authorization,
  notFound,
  network,
  unknown,
}

class ScheduleConfirmationState {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final ScheduleConfirmationStatus confirmationStatus;
  final ScheduleConfirmationFailure? failure;

  const ScheduleConfirmationState({
    this.selectedDate,
    this.selectedTime,
    this.confirmationStatus = ScheduleConfirmationStatus.idle,
    this.failure,
  });

  bool get isConfirming =>
      confirmationStatus == ScheduleConfirmationStatus.inProgress;
  bool get confirmationSucceeded =>
      confirmationStatus == ScheduleConfirmationStatus.success;
  bool get confirmationFailed =>
      confirmationStatus == ScheduleConfirmationStatus.failure;
  bool get canConfirm =>
      selectedDate != null && selectedTime != null && !isConfirming;

  DateTime? get startDateTime {
    final date = selectedDate;
    final time = selectedTime;
    if (date == null || time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  ScheduleConfirmationState copyWith({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    ScheduleConfirmationStatus? confirmationStatus,
    ScheduleConfirmationFailure? failure,
    bool clearFailure = false,
  }) {
    return ScheduleConfirmationState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      confirmationStatus: confirmationStatus ?? this.confirmationStatus,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
