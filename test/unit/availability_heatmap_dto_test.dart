import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/availability/domain/availability_heatmap_dto.dart';
import 'package:planify/features/availability/domain/slot_heatmap_dto.dart';

void main() {
  group('AvailabilityHeatmapDto', () {
    test('represents the participant total and immutable heatmap slots', () {
      final sourceSlots = [
        SlotHeatmapDto(weekDay: 1, hourBlock: 10, availableCount: 3),
      ];

      final heatmap = AvailabilityHeatmapDto(
        totalParticipants: 5,
        slots: sourceSlots,
      );
      sourceSlots.add(
        SlotHeatmapDto(weekDay: 2, hourBlock: 11, availableCount: 1),
      );

      expect(heatmap.totalParticipants, 5);
      expect(heatmap.slots, [
        SlotHeatmapDto(weekDay: 1, hourBlock: 10, availableCount: 3),
      ]);
      expect(
        () => heatmap.slots.add(
          SlotHeatmapDto(weekDay: 2, hourBlock: 11, availableCount: 1),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects a negative participant total', () {
      expect(
        () => AvailabilityHeatmapDto(totalParticipants: -1, slots: const []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SlotHeatmapDto', () {
    test('uses value equality', () {
      expect(
        SlotHeatmapDto(weekDay: 1, hourBlock: 10, availableCount: 3),
        SlotHeatmapDto(weekDay: 1, hourBlock: 10, availableCount: 3),
      );
    });

    test('rejects invalid slot coordinates and negative availability', () {
      expect(
        () => SlotHeatmapDto(weekDay: -1, hourBlock: 10, availableCount: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SlotHeatmapDto(weekDay: 7, hourBlock: 10, availableCount: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SlotHeatmapDto(weekDay: 1, hourBlock: 24, availableCount: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SlotHeatmapDto(weekDay: 1, hourBlock: 10, availableCount: -1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
