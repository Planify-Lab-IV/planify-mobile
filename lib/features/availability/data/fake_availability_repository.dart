import '../domain/availability_heatmap_dto.dart';
import '../domain/availability_repository.dart';
import '../domain/slot.dart';
import '../domain/slot_heatmap_dto.dart';

class FakeAvailabilityRepository implements AvailabilityRepository {
  static final _defaultHeatmap = AvailabilityHeatmapDto(
    totalParticipants: 5,
    slots: [
      SlotHeatmapDto(weekDay: 0, hourBlock: 9, availableCount: 0),
      SlotHeatmapDto(weekDay: 1, hourBlock: 10, availableCount: 2),
      SlotHeatmapDto(weekDay: 2, hourBlock: 11, availableCount: 3),
      SlotHeatmapDto(weekDay: 3, hourBlock: 12, availableCount: 5),
    ],
  );

  final Duration delay;
  final Map<String, List<Slot>> _availabilityByEvent = {};
  final Map<String, AvailabilityHeatmapDto> _heatmapByEvent = {};

  FakeAvailabilityRepository({
    this.delay = const Duration(milliseconds: 300),
    Map<String, List<Slot>>? initialAvailabilityByEvent,
    Map<String, AvailabilityHeatmapDto>? initialHeatmapByEvent,
  }) {
    initialAvailabilityByEvent?.forEach((eventId, slots) {
      _availabilityByEvent[eventId] = List<Slot>.from(slots);
    });
    initialHeatmapByEvent?.forEach((eventId, heatmap) {
      _heatmapByEvent[eventId] = _copyHeatmap(heatmap);
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
    return _copyHeatmap(_heatmapByEvent[eventId] ?? _defaultHeatmap);
  }

  static AvailabilityHeatmapDto _copyHeatmap(AvailabilityHeatmapDto heatmap) {
    return AvailabilityHeatmapDto(
      totalParticipants: heatmap.totalParticipants,
      slots: heatmap.slots,
    );
  }
}
