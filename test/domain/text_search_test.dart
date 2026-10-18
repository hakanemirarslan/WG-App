import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/text_search.dart';

void main() {
  group('normalizeForSearch', () {
    test('folds umlauts so Spulmittel matches Spülmittel', () {
      expect(normalizeForSearch('Spülmittel'), normalizeForSearch('Spulmittel'));
      expect(normalizeForSearch('Küchenrolle'), 'kuchenrolle');
      expect(normalizeForSearch('Öl'), 'ol');
    });

    test('is case insensitive', () {
      expect(normalizeForSearch('MILCH'), 'milch');
    });

    test('folds sharp s', () {
      expect(normalizeForSearch('Straße'), 'strasse');
    });

    test('trims whitespace and handles empty input', () {
      expect(normalizeForSearch('  Milk '), 'milk');
      expect(normalizeForSearch(''), '');
    });
  });
}
