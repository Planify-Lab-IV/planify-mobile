import '../domain/availability_repository.dart';
import '../domain/availability_heatmap_dto.dart';
import '../domain/slot.dart';

class FakeAvailabilityRepository implements AvailabilityRepository {
  final Duration delay;
  final Map<String, List<Slot>> _availabilityByEvent = {};

  FakeAvailabilityRepository({
    this.delay = const Duration(milliseconds: 300),
    Map<String, List<Slot>>? initialAvailabilityByEvent,
  }) {
    initialAvailabilityByEvent?.forEach((eventId, slots) {
      _availabilityByEvent[eventId] = List<Slot>.from(slots);
    });
  }

  @override
  Future<List<Slot>> load(String eventId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return List<Slot>.from(_availabilityByEvent[eventId] ?? const []);
  }

  @override
  Future<void> save(String eventId, List<Slot> slots) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    _availabilityByEvent[eventId] = List<Slot>.from(slots);
  }

  @override
  Future<AvailabilityHeatmapDto> heatmap(String eventId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return AvailabilityHeatmapDto(totalParticipants: 0, slots: const []);
  }
}
