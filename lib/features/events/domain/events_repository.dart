import 'event.dart';
import 'event_draft.dart';
import 'attendance_status.dart';

abstract class EventsRepository {
  Future<Event> createEvent(EventDraft draft, String organizerId);
  Future<Event?> getEvent(String eventId);
  Future<void> cancel(String eventId);
  Future<AttendanceStatus> getAttendance(String eventId, String participantId);
  Future<void> confirmAssistance(
    String eventId,
    String participantId,
    AttendanceResponse response,
  );
}
