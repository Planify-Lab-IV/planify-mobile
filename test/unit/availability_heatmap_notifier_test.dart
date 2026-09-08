import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/availability/domain/availability_heatmap_dto.dart';
import 'package:planify/features/availability/domain/availability_repository.dart';
import 'package:planify/features/availability/domain/slot.dart';
import 'package:planify/features/availability/domain/slot_heatmap_dto.dart';
import 'package:planify/features/availability/presentation/controllers/availability_heatmap_notifier.dart';
import 'package:planify/features/availability/presentation/controllers/availability_heatmap_state.dart';

void main() {
  group('AvailabilityHeatmapNotifier', () {
    const eventId = 'evt-1';

    test('loads the heatmap for its event', () async {
      final expectedHeatmap = AvailabilityHeatmapDto(
        totalParticipants: 5,
        slots: [
          SlotHeatmapDto(weekDay: 1, hourBlock: 10, availableCount: 3),
        ],
      );
      final repository = _ControllableAvailabilityRepository(
        heatmapResult: expectedHeatmap,
      );
      final notifier = AvailabilityHeatmapNotifier(
        repository: repository,
        eventId: eventId,
      );
      addTearDown(notifier.dispose);

      expect(notifier.state.isLoading, isTrue);
      await notifier.load();

      expect(notifier.state.loadStatus, AvailabilityHeatmapLoadStatus.success);
      expect(notifier.state.heatmap?.totalParticipants, 5);
      expect(notifier.state.heatmap?.slots, expectedHeatmap.slots);
    });

    test('exposes an error and can retry loading the heatmap', () async {
      final repository = _ControllableAvailabilityRepository(
        heatmapResult: AvailabilityHeatmapDto(
          totalParticipants: 1,
          slots: const [],
        ),
        shouldFail: true,
      );
      final notifier = AvailabilityHeatmapNotifier(
        repository: repository,
        eventId: eventId,
      );
      addTearDown(notifier.dispose);

      await notifier.load();

      expect(notifier.state.hasLoadError, isTrue);
      expect(notifier.state.heatmap, isNull);

      repository.shouldFail = false;
      await notifier.load();

      expect(notifier.state.loadStatus, AvailabilityHeatmapLoadStatus.success);
      expect(notifier.state.heatmap?.totalParticipants, 1);
    });
  });
}

class _ControllableAvailabilityRepository implements AvailabilityRepository {
  final AvailabilityHeatmapDto heatmapResult;
  bool shouldFail;

  _ControllableAvailabilityRepository({
    required this.heatmapResult,
    this.shouldFail = false,
  });

  @override
  Future<AvailabilityHeatmapDto> heatmap(String eventId) async {
    if (shouldFail) {
      throw Exception('Unable to load availability heatmap');
    }
    return heatmapResult;
  }

  @override
  Future<List<Slot>> load(String eventId) async => [];

  @override
  Future<void> save(String eventId, List<Slot> slots) async {}
}
