import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/availability/domain/slot.dart';

void main() {
  group('Slot', () {
    test('represents a valid day and hour', () {
      final slot = Slot(weekDay: 6, hourBlock: 23);

      expect(slot.weekDay, 6);
      expect(slot.hourBlock, 23);
    });

    test('uses value equality and can be de-duplicated in a set', () {
      final slots = <Slot>{
        Slot(weekDay: 1, hourBlock: 9),
        Slot(weekDay: 1, hourBlock: 9),
        Slot(weekDay: 1, hourBlock: 10),
      };

      expect(slots, hasLength(2));
      expect(
        Slot(weekDay: 1, hourBlock: 9),
        equals(Slot(weekDay: 1, hourBlock: 9)),
      );
    });

    test('rejects a day outside the weekly grid', () {
      expect(
        () => Slot(weekDay: -1, hourBlock: 12),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Slot(weekDay: 7, hourBlock: 12),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an hour outside the daily grid', () {
      expect(
        () => Slot(weekDay: 0, hourBlock: -1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Slot(weekDay: 0, hourBlock: 24),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
