import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class Settlement {
  final String id;
  final String from;
  final String to;
  final String fromName;
  final String toName;
  final int cents;
  final DateTime createdAt;

  Settlement({
    required this.id,
    required this.from,
    required this.to,
    required this.fromName,
    required this.toName,
    required this.cents,
    required this.createdAt,
  });

  factory Settlement.fromMap(Map<String, dynamic> map) => Settlement(
        id: map['id'] as String,
        from: map['from_user'] as String,
        to: map['to_user'] as String,
        fromName: (map['sender'] as Map<String, dynamic>)['display_name'] as String,
        toName: (map['receiver'] as Map<String, dynamic>)['display_name'] as String,
        cents: map['amount_cents'] as int,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );
}

class SettlementsRepository {
  Future<List<Settlement>> fetchSettlements(String groupId) async {
    final rows = await supabase
        .from('settlements')
        .select(
          'id, from_user, to_user, amount_cents, created_at, '
          'sender:profiles!settlements_from_user_fkey(display_name), '
          'receiver:profiles!settlements_to_user_fkey(display_name)',
        )
        .eq('group_id', groupId)
        .order('created_at');
    return rows.map(Settlement.fromMap).toList();
  }

  /// Records "[from] paid [to]" (SPEC 9). The `record_settlement` RPC checks
  /// that the caller is one of the two and that both belong to the group.
  Future<void> recordSettlement({
    required String groupId,
    required String from,
    required String to,
    required int cents,
  }) {
    return supabase.rpc('record_settlement', params: {
      'gid': groupId,
      'from_id': from,
      'to_id': to,
      'amount': cents,
    });
  }

  /// Settlements are only ever inserted (there is no undo in V1), so one
  /// filtered subscription is enough.
  RealtimeChannel subscribe(String groupId, void Function() onChange) {
    return supabase
        .channel('settlements:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'settlements',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
