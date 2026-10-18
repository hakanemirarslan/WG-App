/// Balance calculation (SPEC 4). Pure Dart: no Flutter or Supabase imports.
/// Balances are never stored, they are computed from expenses, shares and
/// settlements every time.
library;

import 'split.dart';

class BalanceExpense {
  final String paidBy;
  final int amountCents;
  final DateTime date;
  final List<ExpenseShare> shares;

  const BalanceExpense({
    required this.paidBy,
    required this.amountCents,
    required this.date,
    required this.shares,
  });
}

class BalanceSettlement {
  final String from;
  final String to;
  final int cents;
  final DateTime createdAt;

  const BalanceSettlement({
    required this.from,
    required this.to,
    required this.cents,
    required this.createdAt,
  });
}

/// `balance = paid - own shares + settlements sent - settlements received`.
/// Positive: the group owes this person. Negative: this person owes the group.
///
/// [memberIds] are listed with 0 even without activity. People who only
/// appear in the data (former members) are included too, so their open
/// balance is not lost. [until] (inclusive) ignores everything after it, which
/// gives the balance as it was at the end of a past month.
Map<String, int> calculateBalances({
  required Iterable<BalanceExpense> expenses,
  required Iterable<BalanceSettlement> settlements,
  Iterable<String> memberIds = const [],
  DateTime? until,
}) {
  final balances = <String, int>{for (final id in memberIds) id: 0};
  void add(String userId, int cents) => balances[userId] = (balances[userId] ?? 0) + cents;

  for (final expense in expenses) {
    if (until != null && expense.date.isAfter(until)) continue;
    add(expense.paidBy, expense.amountCents);
    for (final share in expense.shares) {
      add(share.userId, -share.shareCents);
    }
  }
  for (final settlement in settlements) {
    if (until != null && settlement.createdAt.isAfter(until)) continue;
    add(settlement.from, settlement.cents);
    add(settlement.to, -settlement.cents);
  }
  return balances;
}

/// SPEC 4: all balances of a group add up to 0. Anything else is a bug in the
/// data (e.g. shares that do not match their expense).
bool balancesAddUp(Map<String, int> balances) =>
    balances.values.fold(0, (sum, balance) => sum + balance) == 0;
