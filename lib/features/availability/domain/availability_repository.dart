import 'availability_heatmap_dto.dart';
import 'slot.dart';

abstract class AvailabilityRepository {
  Future<List<Slot>> load(String eventId);
  Future<void> save(String eventId, List<Slot> slots);
  Future<AvailabilityHeatmapDto> heatmap(String eventId);
}
