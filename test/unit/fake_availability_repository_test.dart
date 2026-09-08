import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/availability/data/fake_availability_repository.dart';
import 'package:planify/features/availability/domain/availability_heatmap_dto.dart';
import 'package:planify/features/availability/domain/slot.dart';
import 'package:planify/features/availability/domain/slot_heatmap_dto.dart';

void main() {
  group('FakeAvailabilityRepository', () {
    test(
      'returns an empty availability when an event has no saved slots',
      () async {
        final repository = FakeAvailabilityRepository(delay: Duration.zero);

        expect(await repository.load('evt-1'), isEmpty);
      },
    );

    test('loads the availability supplied for an event', () async {
      final initialSlots = [
        Slot(dayOfWeek: 1, hour: 9),
        Slot(dayOfWeek: 4, hour: 18),
      ];
      final repository = FakeAvailabilityRepository(
        delay: Duration.zero,
        initialAvailabilityByEvent: {'evt-1': initialSlots},
      );

      expect(await repository.load('evt-1'), initialSlots);
    });

    test('save replaces the complete availability for an event', () async {
      final repository = FakeAvailabilityRepository(
        delay: Duration.zero,
        initialAvailabilityByEvent: {
          'evt-1': [Slot(dayOfWeek: 0, hour: 8)],
        },
      );
      final replacementSlots = [
        Slot(dayOfWeek: 2, hour: 12),
        Slot(dayOfWeek: 6, hour: 20),
      ];

      await repository.save('evt-1', replacementSlots);

      expect(await repository.load('evt-1'), replacementSlots);
    });

    test(
      'does not expose mutable references to its stored availability',
      () async {
        final initialSlots = [Slot(dayOfWeek: 1, hour: 9)];
        final repository = FakeAvailabilityRepository(
          delay: Duration.zero,
          initialAvailabilityByEvent: {'evt-1': initialSlots},
        );

        initialSlots.add(Slot(dayOfWeek: 2, hour: 10));
        final loadedSlots = await repository.load('evt-1');
        loadedSlots.add(Slot(dayOfWeek: 3, hour: 11));

        expect(await repository.load('evt-1'), [Slot(dayOfWeek: 1, hour: 9)]);
      },
    );

    test('returns a heatmap with distinct availability levels by default',
        () async {
      final repository = FakeAvailabilityRepository(delay: Duration.zero);

      final heatmap = await repository.heatmap('evt-1');

      expect(heatmap.totalParticipants, 5);
      expect(
        heatmap.slots.map((slot) => slot.availableCount),
        containsAll([0, 2, 3, 5]),
      );
    });

    test('loads the heatmap supplied for an event', () async {
      final expectedHeatmap = AvailabilityHeatmapDto(
        totalParticipants: 2,
        slots: [
          SlotHeatmapDto(weekDay: 4, hourBlock: 18, availableCount: 1),
        ],
      );
      final repository = FakeAvailabilityRepository(
        delay: Duration.zero,
        initialHeatmapByEvent: {'evt-1': expectedHeatmap},
      );

      final heatmap = await repository.heatmap('evt-1');

      expect(heatmap.totalParticipants, expectedHeatmap.totalParticipants);
      expect(heatmap.slots, expectedHeatmap.slots);
      expect(identical(heatmap, expectedHeatmap), isFalse);
    });
  });
}
