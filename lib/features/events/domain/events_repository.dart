import 'event.dart';
import 'event_draft.dart';

abstract class EventsRepository {
  Future<Event> createEvent(EventDraft draft);
  Future<Event?> getEvent(String eventId);
  Future<void> cancel(String eventId);
}
