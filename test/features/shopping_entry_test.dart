import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/shopping_list/data/shopping_repository.dart';

Map<String, dynamic> _row({Object? groupItems, Object? adder}) => {
  'id': 'e1',
  'group_item_id': 'gi1',
  'note': null,
  'added_by': 'u1',
  'status': 'open',
  'bought_at': null,
  'created_at': '2026-10-25T10:00:00Z',
  'expense_id': null,
  'group_items': groupItems,
  'adder': adder,
  'buyer': null,
};

void main() {
  group('ShoppingEntry.fromMap', () {
    test('reads the product and adder names', () {
      final entry = ShoppingEntry.fromMap(
        _row(
          groupItems: {'custom_name': 'Milch', 'catalog_items': null},
          adder: {'display_name': 'Ana'},
        ),
      );
      expect(entry.name.localized('de'), 'Milch');
      expect(entry.addedByName, 'Ana');
    });

    test('a product or adder hidden by RLS (null join) does not throw', () {
      final entry = ShoppingEntry.fromMap(_row());
      expect(entry.name.localized('de'), '');
      expect(entry.addedByName, '');
    });
  });
}
