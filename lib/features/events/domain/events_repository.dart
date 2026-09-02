import 'event.dart';

abstract class EventsRepository {
  Future<Event?> getEvent(String eventId);
  Future<void> cancel(String eventId);
}
