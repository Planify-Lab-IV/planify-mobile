import 'event.dart';
import 'event_draft.dart';

abstract class EventsRepository {
  Future<Event> createEvent(EventDraft draft);
}
