import 'activity_entry.dart';
import 'unread_counts.dart';

abstract interface class ActivityLogRepository {
  Future<List<ActivityEntry>> listEventActivity(String eventId);
  Future<UnreadCounts> getUnreadCounts();
  Future<void> markEventAsRead(String eventId);
}
