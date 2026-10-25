import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/validation.dart';

void main() {
  group('isValidEmail', () {
    test('accepts normal addresses, also with surrounding spaces', () {
      expect(isValidEmail('ana@example.com'), isTrue);
      expect(isValidEmail('ana.yilmaz+wg@mail.example.de'), isTrue);
      expect(isValidEmail('  ana@example.com  '), isTrue);
    });

    test('rejects addresses without @, domain or top-level domain', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('ana'), isFalse);
      expect(isValidEmail('ana@'), isFalse);
      expect(isValidEmail('@example.com'), isFalse);
      expect(isValidEmail('ana@example'), isFalse);
      expect(isValidEmail('ana@example.c'), isFalse);
      expect(isValidEmail('ana @example.com'), isFalse);
      expect(isValidEmail('ana@@example.com'), isFalse);
    });
  });

  group('normalizePhone', () {
    test('keeps the country code and drops separators', () {
      expect(normalizePhone('+49 151 2345678'), '+491512345678');
      expect(normalizePhone('+49 (151) 234-56/78'), '+491512345678');
      expect(normalizePhone('+90 532 123 45 67'), '+905321234567');
    });

    test('reads a leading 00 as +', () {
      expect(normalizePhone('0049 1512345678'), '+491512345678');
    });

    test('rejects numbers without country code, letters, too short or too long', () {
      expect(normalizePhone(''), isNull);
      expect(normalizePhone('0151 2345678'), isNull);
      expect(normalizePhone('+49 151 abc'), isNull);
      expect(normalizePhone('+4912345'), isNull); // 7 digits
      expect(normalizePhone('+1234567890123456'), isNull); // 16 digits
    });

    test('accepts the shortest and longest allowed lengths', () {
      expect(normalizePhone('+12345678'), '+12345678');
      expect(normalizePhone('+123456789012345'), '+123456789012345');
    });
  });
}
