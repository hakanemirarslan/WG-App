/// Who owes whom (person detail view). Pure Dart: no Flutter or Supabase imports.
///
/// The balance (SPEC 4) says how much one person owes the group in total. This looks
/// at the same data per pair of people: each expense makes every participant owe the
/// payer their share, settlements reduce that, and debts in both directions net out
/// to one number per pair. The per-person totals still match the balance.
library;

import 'balance.dart';

enum DebtSource { expense, settlement }

/// One expense share or settlement that changed what a person owes another.
class DebtEntry {
  final DebtSource source;

  /// `BalanceExpense.id` / `BalanceSettlement.id`, if the caller provided one.
  final String? sourceId;
  final DateTime date;

  /// Positive: the person owes the other more because of this. Negative: less.
  final int cents;

  const DebtEntry({
    required this.source,
    required this.sourceId,
    required this.date,
    required this.cents,
  });
}

/// The net debt between one person and [otherId].
class PairDebt {
  final String otherId;

  /// Positive: the person owes [otherId]. Negative: [otherId] owes the person.
  final int cents;

  /// Everything behind [cents], newest first; the entries add up to [cents].
  final List<DebtEntry> entries;

  const PairDebt({required this.otherId, required this.cents, required this.entries});
}

/// Net debt of [userId] towards everyone they share an open amount with, largest first
/// (ties by user id). Settled pairs (net 0) are left out.
///
/// Summing [PairDebt.cents] over the result gives `-balance(userId)`.
List<PairDebt> pairDebtsOf(
  String userId, {
  required Iterable<BalanceExpense> expenses,
  required Iterable<BalanceSettlement> settlements,
}) {
  final entriesByOther = <String, List<DebtEntry>>{};
  void add(String otherId, DebtEntry entry) =>
      entriesByOther.putIfAbsent(otherId, () => []).add(entry);

  for (final expense in expenses) {
    if (expense.paidBy == userId) {
      // Everyone else who takes part owes the user their share.
      for (final share in expense.shares) {
        if (share.userId == userId) continue;
        add(
          share.userId,
          DebtEntry(
            source: DebtSource.expense,
            sourceId: expense.id,
            date: expense.date,
            cents: -share.shareCents,
          ),
        );
      }
    } else {
      // The user owes the payer their own share, if they take part.
      for (final share in expense.shares) {
        if (share.userId != userId) continue;
        add(
          expense.paidBy,
          DebtEntry(
            source: DebtSource.expense,
            sourceId: expense.id,
            date: expense.date,
            cents: share.shareCents,
          ),
        );
      }
    }
  }

  for (final settlement in settlements) {
    if (settlement.from == userId) {
      // The user paid [to]: owes them less.
      add(
        settlement.to,
        DebtEntry(
          source: DebtSource.settlement,
          sourceId: settlement.id,
          date: settlement.createdAt,
          cents: -settlement.cents,
        ),
      );
    } else if (settlement.to == userId) {
      // [from] paid the user: the user owes them more (or is owed less).
      add(
        settlement.from,
        DebtEntry(
          source: DebtSource.settlement,
          sourceId: settlement.id,
          date: settlement.createdAt,
          cents: settlement.cents,
        ),
      );
    }
  }

  final debts = <PairDebt>[
    for (final MapEntry(key: otherId, value: entries) in entriesByOther.entries)
      if (entries.fold(0, (sum, e) => sum + e.cents) != 0)
        PairDebt(
          otherId: otherId,
          cents: entries.fold(0, (sum, e) => sum + e.cents),
          entries: [...entries]..sort((a, b) => b.date.compareTo(a.date)),
        ),
  ];
  debts.sort((a, b) {
    final bySize = b.cents.abs().compareTo(a.cents.abs());
    return bySize != 0 ? bySize : a.otherId.compareTo(b.otherId);
  });
  return debts;
}
