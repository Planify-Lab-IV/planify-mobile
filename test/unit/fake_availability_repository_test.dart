import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/availability/data/fake_availability_repository.dart';
import 'package:planify/features/availability/domain/slot.dart';

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
  });
}
