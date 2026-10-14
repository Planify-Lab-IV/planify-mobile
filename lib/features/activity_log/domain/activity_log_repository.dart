import 'activity_entry.dart';

abstract interface class ActivityLogRepository {
  Future<List<ActivityEntry>> listEventActivity(String eventId);
}
