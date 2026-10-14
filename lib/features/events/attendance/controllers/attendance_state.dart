import '../../domain/attendance_status.dart';

enum AttendanceSaveStatus { idle, saving, success, error }

class AttendanceState {
  final AttendanceStatus status;
  final AttendanceSaveStatus saveStatus;

  const AttendanceState({
    this.status = AttendanceStatus.noResponse,
    this.saveStatus = AttendanceSaveStatus.idle,
  });

  bool get isSaving => saveStatus == AttendanceSaveStatus.saving;
  bool get hasSaveError => saveStatus == AttendanceSaveStatus.error;

  AttendanceState copyWith({
    AttendanceStatus? status,
    AttendanceSaveStatus? saveStatus,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }
}
