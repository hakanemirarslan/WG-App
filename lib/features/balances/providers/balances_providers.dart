import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../../../domain/balance.dart';
import '../../../domain/debt_simplifier.dart';
import '../../../domain/split.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../groups/providers/groups_providers.dart';
import '../data/settlements_repository.dart';

final settlementsRepositoryProvider = Provider<SettlementsRepository>(
  (ref) => SettlementsRepository(),
);

/// Live settlement list, same pattern as the expense list.
final settlementsProvider = StreamProvider.autoDispose.family<List<Settlement>, String>((
  ref,
  groupId,
) {
  final repository = ref.watch(settlementsRepositoryProvider);
  final controller = StreamController<List<Settlement>>();

  Future<void> load() async {
    try {
      final settlements = await repository.fetchSettlements(groupId);
      if (!controller.isClosed) controller.add(settlements);
    } catch (error, stack) {
      if (!controller.isClosed) controller.addError(error, stack);
    }
  }

  load();
  final channel = repository.subscribe(groupId, load);
  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });
  return controller.stream;
});

/// The expense data the pure `domain/` code works with.
List<BalanceExpense> balanceExpensesOf(List<Expense> expenses) {
  return [
    for (final e in expenses)
      BalanceExpense(
        id: e.id,
        paidBy: e.paidBy,
        amountCents: e.amountCents,
        date: e.date,
        shares: [for (final s in e.shares) ExpenseShare(s.userId, s.shareCents)],
      ),
  ];
}

/// Everything the balance screens need, computed from the live expense,
/// settlement and member data (balances are never stored, SPEC 4).
class BalanceData {
  /// Balance per user id, including former members who still have activity.
  final Map<String, int> balances;
  final Map<String, String> names;
  final Set<String> activeMemberIds;
  final List<Transfer> transfers;

  /// False means the data is inconsistent (balances do not add up to 0).
  final bool consistent;

  BalanceData({
    required this.balances,
    required this.names,
    required this.activeMemberIds,
    required this.transfers,
    required this.consistent,
  });

  /// Active members always, former members only while they still owe/are owed.
  List<String> get visibleUserIds {
    final ids =
        balances.keys.where((id) => activeMemberIds.contains(id) || balances[id] != 0).toList()
          ..sort((a, b) {
            final byBalance = balances[b]!.compareTo(balances[a]!);
            return byBalance != 0 ? byBalance : a.compareTo(b);
          });
    return ids;
  }
}

final balancesProvider = Provider.autoDispose.family<AsyncValue<BalanceData>, String>((
  ref,
  groupId,
) {
  final expensesAsync = ref.watch(expensesProvider(groupId));
  final settlementsAsync = ref.watch(settlementsProvider(groupId));
  final membersAsync = ref.watch(groupMembersProvider(groupId));

  for (final async in [expensesAsync, settlementsAsync, membersAsync]) {
    if (async.hasError) return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
  }
  final expenses = expensesAsync.value;
  final settlements = settlementsAsync.value;
  final members = membersAsync.value;
  if (expenses == null || settlements == null || members == null) {
    return const AsyncLoading();
  }

  // Names of former members only exist on the expenses/settlements they are part of.
  final names = {for (final m in members) m.userId: m.displayName};
  for (final expense in expenses) {
    names.putIfAbsent(expense.paidBy, () => expense.paidByName);
    for (final share in expense.shares) {
      names.putIfAbsent(share.userId, () => share.name);
    }
  }
  for (final settlement in settlements) {
    names.putIfAbsent(settlement.from, () => settlement.fromName);
    names.putIfAbsent(settlement.to, () => settlement.toName);
  }

  final activeIds = members.map((m) => m.userId).toSet();
  final balances = calculateBalances(
    expenses: balanceExpensesOf(expenses),
    settlements: [
      for (final s in settlements)
        BalanceSettlement(from: s.from, to: s.to, cents: s.cents, createdAt: s.createdAt),
    ],
    memberIds: activeIds,
  );
  final consistent = balancesAddUp(balances);

  return AsyncData(
    BalanceData(
      balances: balances,
      names: names,
      activeMemberIds: activeIds,
      transfers: consistent ? simplifyDebts(balances) : const [],
      consistent: consistent,
    ),
  );
});
