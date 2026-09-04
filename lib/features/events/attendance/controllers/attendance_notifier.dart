import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/attendance_status.dart';
import '../../domain/events_repository.dart';
import 'attendance_state.dart';

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final EventsRepository repository;
  final String eventId;
  final String participantId;

  AttendanceNotifier({
    required this.repository,
    required this.eventId,
    required this.participantId,
  }) : super(const AttendanceState()) {
    load();
  }

  Future<void> load() async {
    try {
      final status = await repository.getAttendance(eventId, participantId);
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

  Future<void> respond(AttendanceStatus status) async {
    if (state.isSaving) return;

    final previousStatus = state.status;
    state = state.copyWith(
      status: status,
      saveStatus: AttendanceSaveStatus.saving,
    );

    try {
      await repository.confirmAssistance(eventId, participantId, status.name);
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
