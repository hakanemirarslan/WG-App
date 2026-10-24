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

    test('folds Turkish letters so sut matches süt and cay matches çay', () {
      expect(normalizeForSearch('Süt'), normalizeForSearch('sut'));
      expect(normalizeForSearch('Çay'), 'cay');
      expect(normalizeForSearch('Şeker'), 'seker');
      expect(normalizeForSearch('Pirinç'), 'pirinc');
      expect(normalizeForSearch('Yağ'), 'yag');
    });

    test('folds the Turkish dotted and dotless i', () {
      expect(normalizeForSearch('İstanbul'), 'istanbul');
      expect(normalizeForSearch('ISIK'), 'isik');
      expect(normalizeForSearch('ışık'), 'isik');
    });

    test('trims whitespace and handles empty input', () {
      expect(normalizeForSearch('  Milk '), 'milk');
      expect(normalizeForSearch(''), '');
    });
  });
}
