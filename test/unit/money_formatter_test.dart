import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/formatting/money_formatter.dart';

void main() {
  group('formatCents', () {
    test('formats zero, cents, thousands and negative amounts', () {
      expect(formatCents(0), '0,00');
      expect(formatCents(5), '0,05');
      expect(formatCents(123456), '1.234,56');
      expect(formatCents(-123456), '-1.234,56');
    });

    test('uses the requested locale separators', () {
      expect(formatCents(123456, locale: 'en_US'), '1,234.56');
    });
  });

  group('parseToCents', () {
    test('parses whole amounts and decimal amounts to integer cents', () {
      expect(parseToCents('0'), 0);
      expect(parseToCents('12'), 1200);
      expect(parseToCents('12,5'), 1250);
      expect(parseToCents('12.50'), 1250);
      expect(parseToCents('-0,05'), -5);
    });

    test('accepts correctly grouped Spanish and English amounts', () {
      expect(parseToCents('1.234,56'), 123456);
      expect(parseToCents('1,234.56'), 123456);
      expect(parseToCents('  12 345,67  '), 1234567);
    });

    test('rejects empty, malformed and ambiguous amounts', () {
      for (final input in ['', '12,', '1.234.56', '1,234,56', '12a']) {
        expect(() => parseToCents(input), throwsFormatException);
      }
    });
  });
}
