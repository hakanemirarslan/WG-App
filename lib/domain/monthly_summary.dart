/// Monthly summary (SPEC 9). Pure Dart: no Flutter or Supabase imports.
/// Only a view on the data: the balance itself is always all-time (SPEC 4).
library;

import 'balance.dart';

class MonthlySummary {
  /// Sum of all expenses dated in the month.
  final int totalCents;
  final int expenseCount;

  /// What each person paid / owes (their shares) for expenses of the month.
  final Map<String, int> paidByUser;
  final Map<String, int> shareByUser;

  /// Balance at the end of the month: everything up to and including its
  /// last day, not only the month itself.
  final Map<String, int> endBalances;

  const MonthlySummary({
    required this.totalCents,
    required this.expenseCount,
    required this.paidByUser,
    required this.shareByUser,
    required this.endBalances,
  });
}

MonthlySummary summarizeMonth({
  required int year,
  required int month,
  required Iterable<BalanceExpense> expenses,
  required Iterable<BalanceSettlement> settlements,
  Iterable<String> memberIds = const [],
}) {
  final start = DateTime(year, month, 1);
  // DateTime normalises month 13 to January of the next year.
  final nextMonth = DateTime(year, month + 1, 1);

  final inMonth = expenses
      .where((e) => !e.date.isBefore(start) && e.date.isBefore(nextMonth))
      .toList();

  final paid = <String, int>{};
  final shares = <String, int>{};
  for (final expense in inMonth) {
    paid[expense.paidBy] = (paid[expense.paidBy] ?? 0) + expense.amountCents;
    for (final share in expense.shares) {
      shares[share.userId] = (shares[share.userId] ?? 0) + share.shareCents;
    }
  }

  return MonthlySummary(
    totalCents: inMonth.fold(0, (sum, e) => sum + e.amountCents),
    expenseCount: inMonth.length,
    paidByUser: paid,
    shareByUser: shares,
    endBalances: calculateBalances(
      expenses: expenses,
      settlements: settlements,
      memberIds: memberIds,
      until: nextMonth.subtract(const Duration(microseconds: 1)),
    ),
  );
}
