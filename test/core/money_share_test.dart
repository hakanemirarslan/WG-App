import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/money.dart';

void main() {
  group('parseShareCents', () {
    test('empty and zero are valid 0 shares', () {
      expect(parseShareCents(''), 0);
      expect(parseShareCents('  '), 0);
      expect(parseShareCents('0'), 0);
      expect(parseShareCents('0,00'), 0);
    });

    test('parses like parseToCents otherwise', () {
      expect(parseShareCents('3,34'), 334);
      expect(parseShareCents('3.3'), 330);
    });

    test('rejects malformed and too large input', () {
      expect(parseShareCents('abc'), isNull);
      expect(parseShareCents('1,234'), isNull);
      expect(parseShareCents('-1'), isNull);
      expect(parseShareCents('100000,01'), isNull);
    });
  });

  group('formatCentsPlain', () {
    test('uses the locale decimal separator and no grouping', () {
      expect(formatCentsPlain(334, locale: 'de'), '3,34');
      expect(formatCentsPlain(334, locale: 'en'), '3.34');
      expect(formatCentsPlain(100000, locale: 'de'), '1000,00');
      expect(formatCentsPlain(5, locale: 'en'), '0.05');
    });

    test('round-trips through parseToCents', () {
      for (final cents in [1, 99, 100, 123456, 10000000]) {
        expect(parseToCents(formatCentsPlain(cents, locale: 'de')), cents);
        expect(parseToCents(formatCentsPlain(cents, locale: 'en')), cents);
      }
    });
  });
}
