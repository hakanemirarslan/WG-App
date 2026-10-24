import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/catalog/data/catalog_repository.dart';

void main() {
  group('ProductName.localized', () {
    final catalog = ProductName(nameDe: 'Milch', nameEn: 'Milk', nameTr: 'Süt');

    test('picks the name of the language', () {
      expect(catalog.localized('de'), 'Milch');
      expect(catalog.localized('en'), 'Milk');
      expect(catalog.localized('tr'), 'Süt');
    });

    test('Turkish falls back to English while the Turkish name is missing', () {
      final noTurkish = ProductName(nameDe: 'Milch', nameEn: 'Milk');
      expect(noTurkish.localized('tr'), 'Milk');
    });

    test('free-text names are shown as typed in every language', () {
      final custom = ProductName(customName: 'Hafermilch');
      for (final lang in ['de', 'en', 'tr']) {
        expect(custom.localized(lang), 'Hafermilch');
      }
    });
  });

  group('CatalogItem.localized', () {
    test('Turkish uses nameTr, then English', () {
      final item = CatalogItem(
        id: '1',
        nameDe: 'Tee',
        nameEn: 'Tea',
        nameTr: 'Çay',
        category: 'food',
      );
      expect(item.localized('tr'), 'Çay');
      final withoutTr = CatalogItem(
        id: '2',
        nameDe: 'Salz',
        nameEn: 'Salt',
        nameTr: null,
        category: 'food',
      );
      expect(withoutTr.localized('tr'), 'Salt');
      expect(withoutTr.localized('de'), 'Salz');
    });
  });
}
