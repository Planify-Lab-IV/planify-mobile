import 'event.dart';
import 'event_draft.dart';
import 'attendance_status.dart';

abstract class EventsRepository {
  Future<Event> createEvent(EventDraft draft);
  Future<Event?> getEvent(String eventId);
  Future<void> cancel(String eventId);
  Future<void> confirmSchedule(String eventId, DateTime startDateTime);
  Future<AttendanceStatus> getCurrentUserAttendance(String eventId);
  Future<void> updateCurrentUserAttendance(
    String eventId,
    AttendanceResponse response,
  );
}
