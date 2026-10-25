import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../catalog/data/catalog_repository.dart';

class ShoppingEntry {
  final String id;
  final String groupItemId;
  final ProductName name;
  final String? note;
  final String addedBy;
  final String addedByName;
  final bool isBought;
  final String? boughtByName;
  final DateTime? boughtAt;
  final DateTime createdAt;

  /// Expense created by ticking this item off with a price (null if none).
  final String? expenseId;

  ShoppingEntry({
    required this.id,
    required this.groupItemId,
    required this.name,
    required this.note,
    required this.addedBy,
    required this.addedByName,
    required this.isBought,
    required this.boughtByName,
    required this.boughtAt,
    required this.createdAt,
    required this.expenseId,
  });

  /// Joined rows can come back null when RLS hides them; such a row then shows an empty
  /// name instead of failing the whole list (defence in depth, the database prevents it).
  factory ShoppingEntry.fromMap(Map<String, dynamic> map) {
    final boughtAt = map['bought_at'] as String?;
    final groupItem = map['group_items'] as Map<String, dynamic>?;
    return ShoppingEntry(
      id: map['id'] as String,
      groupItemId: map['group_item_id'] as String,
      name: groupItem == null ? ProductName() : ProductName.fromGroupItemMap(groupItem),
      note: map['note'] as String?,
      addedBy: map['added_by'] as String,
      addedByName: (map['adder'] as Map<String, dynamic>?)?['display_name'] as String? ?? '',
      isBought: map['status'] == 'bought',
      boughtByName: (map['buyer'] as Map<String, dynamic>?)?['display_name'] as String?,
      boughtAt: boughtAt == null ? null : DateTime.parse(boughtAt),
      createdAt: DateTime.parse(map['created_at'] as String),
      expenseId: map['expense_id'] as String?,
    );
  }
}

class ShoppingRepository {
  static const _recentDays = 7;

  /// Open entries plus entries bought within the last 7 days (SPEC 6).
  Future<List<ShoppingEntry>> fetchEntries(String groupId) async {
    final since = DateTime.now().subtract(const Duration(days: _recentDays)).toUtc();
    final rows = await supabase
        .from('shopping_entries')
        .select(
          'id, group_item_id, note, added_by, status, bought_at, created_at, expense_id, '
          'group_items(custom_name, catalog_items(name_de, name_en, name_tr)), '
          'adder:profiles!shopping_entries_added_by_fkey(display_name), '
          'buyer:profiles!shopping_entries_bought_by_fkey(display_name)',
        )
        .eq('group_id', groupId)
        .or('status.eq.open,bought_at.gte.${since.toIso8601String()}')
        .order('created_at', ascending: false);
    return rows.map(ShoppingEntry.fromMap).toList();
  }

  Future<void> addEntry(String groupId, String groupItemId, String? note) {
    return supabase.from('shopping_entries').insert({
      'group_id': groupId,
      'group_item_id': groupItemId,
      'note': note,
      'added_by': supabase.auth.currentUser!.id,
    });
  }

  Future<void> markBought(String entryId) {
    return supabase
        .from('shopping_entries')
        .update({
          'status': 'bought',
          'bought_by': supabase.auth.currentUser!.id,
          'bought_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', entryId);
  }

  /// Remembers which expense this entry's price created, so undoing can delete it.
  Future<void> linkExpense(String entryId, String expenseId) {
    return supabase.from('shopping_entries').update({'expense_id': expenseId}).eq('id', entryId);
  }

  Future<void> undoBought(String entryId) {
    return supabase
        .from('shopping_entries')
        .update({'status': 'open', 'bought_by': null, 'bought_at': null})
        .eq('id', entryId);
  }

  Future<void> deleteEntry(String entryId) =>
      supabase.from('shopping_entries').delete().eq('id', entryId);

  /// Calls [onChange] whenever an entry of this group changes.
  ///
  /// Two subscriptions on purpose: Realtime cannot filter DELETE events by
  /// `group_id` (the old row only carries the primary key), so deletes are
  /// listened to unfiltered and just trigger a reload (SPEC 13, item 7).
  RealtimeChannel subscribe(String groupId, void Function() onChange) {
    return supabase
        .channel('shopping_entries:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shopping_entries',
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
          table: 'shopping_entries',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
