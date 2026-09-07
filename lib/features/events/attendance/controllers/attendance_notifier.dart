import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/attendance_status.dart';
import '../../domain/events_repository.dart';
import 'attendance_state.dart';

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final EventsRepository repository;
  final String eventId;

  AttendanceNotifier({
    required this.repository,
    required this.eventId,
  }) : super(const AttendanceState()) {
    load();
  }

  Future<void> load() async {
    try {
      final status = await repository.getCurrentUserAttendance(eventId);
      if (!mounted) return;
      state = state.copyWith(
        status: status,
        loadStatus: AttendanceLoadStatus.success,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadStatus: AttendanceLoadStatus.error);
    }
  }

  Future<void> respond(AttendanceResponse response) async {
    if (state.isSaving) return;

    final previousStatus = state.status;
    state = state.copyWith(
      status: response.status,
      saveStatus: AttendanceSaveStatus.saving,
    );

    try {
      await repository.updateCurrentUserAttendance(eventId, response);
      if (!mounted) return;
      state = state.copyWith(saveStatus: AttendanceSaveStatus.success);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        status: previousStatus,
        saveStatus: AttendanceSaveStatus.error,
      );
    }
  }
}
