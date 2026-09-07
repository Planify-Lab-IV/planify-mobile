import '../../domain/attendance_status.dart';

enum AttendanceLoadStatus { loading, success, error }

enum AttendanceSaveStatus { idle, saving, success, error }

class AttendanceState {
  final AttendanceStatus status;
  final AttendanceLoadStatus loadStatus;
  final AttendanceSaveStatus saveStatus;

  const AttendanceState({
    this.status = AttendanceStatus.noResponse,
    this.loadStatus = AttendanceLoadStatus.loading,
    this.saveStatus = AttendanceSaveStatus.idle,
  });

  bool get isLoading => loadStatus == AttendanceLoadStatus.loading;
  bool get hasLoadError => loadStatus == AttendanceLoadStatus.error;
  bool get isSaving => saveStatus == AttendanceSaveStatus.saving;
  bool get hasSaveError => saveStatus == AttendanceSaveStatus.error;
  bool get hasError => hasLoadError || hasSaveError;

  AttendanceState copyWith({
    AttendanceStatus? status,
    AttendanceLoadStatus? loadStatus,
    AttendanceSaveStatus? saveStatus,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }
}
