import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/expenses/domain/split_evenly.dart';

void main() {
  group('splitEvenly', () {
    test('splits an exact total into equal parts', () {
      expect(splitEvenly(1200, 3), [400, 400, 400]);
    });

    test('assigns the complete remainder to the last part', () {
      final parts = splitEvenly(1001, 3);

      expect(parts, [333, 333, 335]);
      expect(parts.reduce((sum, part) => sum + part), 1001);
    });

    test('supports a single part and zero totals', () {
      expect(splitEvenly(1250, 1), [1250]);
      expect(splitEvenly(0, 3), [0, 0, 0]);
    });

    test('rejects invalid totals and part counts', () {
      expect(() => splitEvenly(-1, 2), throwsArgumentError);
      expect(() => splitEvenly(100, 0), throwsArgumentError);
      expect(() => splitEvenly(100, -2), throwsArgumentError);
    });
  });
}
