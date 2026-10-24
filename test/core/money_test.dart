import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/money.dart';

void main() {
  group('parseToCents', () {
    test('accepts comma decimal separator', () {
      expect(parseToCents('23,5'), 2350);
    });

    test('accepts dot decimal separator', () {
      expect(parseToCents('23.50'), 2350);
    });

    test('accepts integer amounts', () {
      expect(parseToCents('23'), 2300);
    });

    test('rejects zero', () {
      expect(parseToCents('0'), isNull);
      expect(parseToCents('0,00'), isNull);
    });

    test('rejects negative amounts', () {
      expect(parseToCents('-5'), isNull);
    });

    test('rejects more than 2 decimal digits', () {
      expect(parseToCents('23,555'), isNull);
    });

    test('rejects non-numeric input', () {
      expect(parseToCents('abc'), isNull);
      expect(parseToCents(''), isNull);
    });

    test('accepts the upper bound of 100.000,00 EUR', () {
      expect(parseToCents('100000.00'), maxAmountCents);
    });

    test('rejects amounts above the upper bound', () {
      expect(parseToCents('100000.01'), isNull);
    });
  });

  group('formatCents', () {
    test('formats with comma decimal separator for de', () {
      // intl inserts a non-breaking space (U+00A0) before the symbol for de_DE.
      expect(formatCents(2350, locale: 'de'), '23,50 €');
    });

    test('formats with dot decimal separator for en', () {
      expect(formatCents(2350, locale: 'en'), '€23.50');
    });

    test('formats with comma decimal separator and dot grouping for tr', () {
      expect(formatCents(123450, locale: 'tr'), '€1.234,50');
    });
  });
}
