import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/auth/domain/registration_rules.dart';

void main() {
  group('isValidRegistrationName', () {
    test('accepts names from 1 to 80 characters', () {
      expect(isValidRegistrationName('A'), isTrue);
      expect(isValidRegistrationName('a' * 80), isTrue);
    });

    test('rejects an empty name and names longer than 80 characters', () {
      expect(isValidRegistrationName(''), isFalse);
      expect(isValidRegistrationName('a' * 81), isFalse);
    });
  });

  group('isValidRegistrationUsername', () {
    test('accepts lowercase letters, digits and underscores from 3 to 30', () {
      expect(isValidRegistrationUsername('abc'), isTrue);
      expect(isValidRegistrationUsername('a' * 30), isTrue);
      expect(isValidRegistrationUsername('planify_2026'), isTrue);
    });

    test('rejects invalid lengths and characters', () {
      expect(isValidRegistrationUsername('ab'), isFalse);
      expect(isValidRegistrationUsername('a' * 31), isFalse);
      expect(isValidRegistrationUsername('Planify'), isFalse);
      expect(isValidRegistrationUsername('planify-user'), isFalse);
    });
  });

  group('isValidRegistrationEmail', () {
    test('accepts a valid email address', () {
      expect(isValidRegistrationEmail('organizer@planify.com'), isTrue);
    });

    test('rejects malformed email addresses', () {
      expect(isValidRegistrationEmail(''), isFalse);
      expect(isValidRegistrationEmail('organizer.planify.com'), isFalse);
      expect(isValidRegistrationEmail('organizer@planify'), isFalse);
      expect(isValidRegistrationEmail('organizer @planify.com'), isFalse);
    });
  });

  group('isValidRegistrationPassword', () {
    test('accepts passwords from 8 to 72 characters', () {
      expect(isValidRegistrationPassword('password'), isTrue);
      expect(isValidRegistrationPassword('a' * 72), isTrue);
    });

    test('rejects passwords outside the allowed length', () {
      expect(isValidRegistrationPassword('a' * 7), isFalse);
      expect(isValidRegistrationPassword('a' * 73), isFalse);
    });
  });
}
