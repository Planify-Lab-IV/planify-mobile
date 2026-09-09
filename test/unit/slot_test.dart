import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/availability/domain/slot.dart';

void main() {
  group('Slot', () {
    test('represents a valid day and hour', () {
      final slot = Slot(dayOfWeek: 6, hour: 23);

      expect(slot.dayOfWeek, 6);
      expect(slot.hour, 23);
    });

    test('uses value equality and can be de-duplicated in a set', () {
      final slots = <Slot>{
        Slot(dayOfWeek: 1, hour: 9),
        Slot(dayOfWeek: 1, hour: 9),
        Slot(dayOfWeek: 1, hour: 10),
      };

      expect(slots, hasLength(2));
      expect(Slot(dayOfWeek: 1, hour: 9), equals(Slot(dayOfWeek: 1, hour: 9)));
    });

    test('rejects a day outside the weekly grid', () {
      expect(
        () => Slot(dayOfWeek: -1, hour: 12),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => Slot(dayOfWeek: 7, hour: 12), throwsA(isA<ArgumentError>()));
    });

    test('rejects an hour outside the daily grid', () {
      expect(() => Slot(dayOfWeek: 0, hour: -1), throwsA(isA<ArgumentError>()));
      expect(() => Slot(dayOfWeek: 0, hour: 24), throwsA(isA<ArgumentError>()));
    });
  });
}
