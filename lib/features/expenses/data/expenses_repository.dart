import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../../domain/split.dart';
import '../../catalog/data/catalog_repository.dart';

class ExpenseShareDetail {
  final String userId;
  final String name;
  final int shareCents;

  ExpenseShareDetail({required this.userId, required this.name, required this.shareCents});
}

class ExpenseItem {
  final ProductName name;
  final PickedProduct product;

  ExpenseItem({required this.name, required this.product});

  /// [map] is a `group_items` row (with `catalog_item_id` and the embedded catalog names).
  factory ExpenseItem.fromGroupItemMap(Map<String, dynamic> map) {
    final catalogItemId = map['catalog_item_id'] as String?;
    return ExpenseItem(
      name: ProductName.fromGroupItemMap(map),
      product: catalogItemId != null
          ? PickedProduct.catalog(catalogItemId)
          : PickedProduct.custom(map['custom_name'] as String),
    );
  }
}

class Expense {
  final String id;
  final String paidBy;
  final String paidByName;
  final int amountCents;
  final String? description;
  final DateTime date;
  final String createdBy;
  final List<ExpenseShareDetail> shares;
  final List<ExpenseItem> items;

  Expense({
    required this.id,
    required this.paidBy,
    required this.paidByName,
    required this.amountCents,
    required this.description,
    required this.date,
    required this.createdBy,
    required this.shares,
    required this.items,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    final shares = (map['expense_shares'] as List).cast<Map<String, dynamic>>();
    final items = (map['expense_items'] as List).cast<Map<String, dynamic>>();
    return Expense(
      id: map['id'] as String,
      paidBy: map['paid_by'] as String,
      paidByName: (map['payer'] as Map<String, dynamic>)['display_name'] as String,
      amountCents: map['amount_cents'] as int,
      description: map['description'] as String?,
      date: DateTime.parse(map['expense_date'] as String),
      createdBy: map['created_by'] as String,
      shares: [
        for (final share in shares)
          ExpenseShareDetail(
            userId: share['user_id'] as String,
            name: (share['profiles'] as Map<String, dynamic>)['display_name'] as String,
            shareCents: share['share_cents'] as int,
          ),
      ]..sort((a, b) => a.name.compareTo(b.name)),
      items: [
        for (final item in items)
          ExpenseItem.fromGroupItemMap(item['group_items'] as Map<String, dynamic>),
      ],
    );
  }

  /// Title for the list: the description, else the item names, else null
  /// (the UI then falls back to a localized "Expense"). SPEC 8.
  String? displayTitle(String languageCode) {
    if (description != null) return description;
    if (items.isEmpty) return null;
    return items.map((item) => item.name.localized(languageCode)).join(', ');
  }
}

class ExpensesRepository {
  Future<List<Expense>> fetchExpenses(String groupId) async {
    final rows = await supabase
        .from('expenses')
        .select(
          'id, paid_by, amount_cents, description, expense_date, created_by, '
          'payer:profiles!expenses_paid_by_fkey(display_name), '
          'expense_shares(user_id, share_cents, profiles(display_name)), '
          'expense_items(group_items(catalog_item_id, custom_name, catalog_items(name_de, name_en)))',
        )
        .eq('group_id', groupId)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(Expense.fromMap).toList();
  }

  /// Creates ([expenseId] null) or edits an expense. Expense, shares and items
  /// are written in one transaction by the `save_expense` RPC, which also
  /// checks totals, membership and permissions (SPEC 13).
  Future<String> saveExpense({
    required String groupId,
    String? expenseId,
    required String paidBy,
    required int amountCents,
    String? description,
    required DateTime date,
    required List<ExpenseShare> shares,
    List<String> itemIds = const [],
  }) async {
    final id = await supabase.rpc('save_expense', params: {
      'gid': groupId,
      'eid': expenseId,
      'payer': paidBy,
      'amount': amountCents,
      'descr': description,
      'exp_date': _dateOnly(date),
      'share_list': [
        for (final share in shares) {'user_id': share.userId, 'share_cents': share.shareCents},
      ],
      'item_list': itemIds,
    });
    return id as String;
  }

  Future<void> deleteExpense(String expenseId) =>
      supabase.from('expenses').delete().eq('id', expenseId);

  /// Calls [onChange] whenever an expense of this group changes. Same two
  /// subscriptions as the shopping list: DELETE events cannot be filtered by
  /// `group_id`, so deletes are listened to unfiltered and only trigger a reload.
  /// Shares and items are written in the same transaction as the expense row,
  /// so a reload after an `expenses` event always sees them.
  RealtimeChannel subscribe(String groupId, void Function() onChange) {
    return supabase
        .channel('expenses:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'expenses',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
