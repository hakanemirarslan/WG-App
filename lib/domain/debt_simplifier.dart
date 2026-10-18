/// Debt simplification (SPEC 5). Pure Dart: no Flutter or Supabase imports.
library;

class Transfer {
  final String from;
  final String to;
  final int cents;

  const Transfer(this.from, this.to, this.cents);

  @override
  bool operator ==(Object other) =>
      other is Transfer && other.from == from && other.to == to && other.cents == cents;

  @override
  int get hashCode => Object.hash(from, to, cents);

  @override
  String toString() => 'Transfer($from -> $to, $cents)';
}

/// Turns balances (positive = is owed money, negative = owes money; the sum
/// must be 0) into a short list of payments that settle everyone.
///
/// Greedy: repeatedly pair the largest debtor with the largest creditor and
/// transfer the smaller of the two amounts. Each step settles at least one
/// person (the last one settles two), so there are at most n-1 transfers.
/// Ties are broken by user id, so the result is deterministic.
List<Transfer> simplifyDebts(Map<String, int> balances) {
  if (balances.values.fold(0, (sum, balance) => sum + balance) != 0) {
    throw ArgumentError('Balances must add up to zero');
  }

  final creditors = {
    for (final e in balances.entries)
      if (e.value > 0) e.key: e.value,
  };
  final debtors = {
    for (final e in balances.entries)
      if (e.value < 0) e.key: -e.value,
  };

  // Largest amount first, user id ascending on ties.
  String largest(Map<String, int> amounts) {
    final ids = amounts.keys.toList()
      ..sort((a, b) {
        final byAmount = amounts[b]!.compareTo(amounts[a]!);
        return byAmount != 0 ? byAmount : a.compareTo(b);
      });
    return ids.first;
  }

  final transfers = <Transfer>[];
  while (creditors.isNotEmpty && debtors.isNotEmpty) {
    final debtor = largest(debtors);
    final creditor = largest(creditors);
    final cents = debtors[debtor]! < creditors[creditor]! ? debtors[debtor]! : creditors[creditor]!;
    transfers.add(Transfer(debtor, creditor, cents));

    debtors[debtor] = debtors[debtor]! - cents;
    creditors[creditor] = creditors[creditor]! - cents;
    if (debtors[debtor] == 0) debtors.remove(debtor);
    if (creditors[creditor] == 0) creditors.remove(creditor);
  }
  return transfers;
}
