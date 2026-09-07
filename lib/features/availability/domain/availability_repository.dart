import 'slot.dart';

abstract class AvailabilityRepository {
  Future<List<Slot>> load(String eventId);
  Future<void> save(String eventId, List<Slot> slots);
}
