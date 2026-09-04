enum AttendanceStatus { noResponse, confirmed, rejected }

enum AttendanceResponse { confirmed, rejected }

extension AttendanceResponseStatus on AttendanceResponse {
  AttendanceStatus get status => switch (this) {
    AttendanceResponse.confirmed => AttendanceStatus.confirmed,
    AttendanceResponse.rejected => AttendanceStatus.rejected,
  };
}
