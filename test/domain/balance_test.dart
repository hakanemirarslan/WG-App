import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/balance.dart';
import 'package:wg_app/domain/split.dart';

BalanceExpense expense(String paidBy, int amount, List<String> participants, {DateTime? date}) {
  return BalanceExpense(
    paidBy: paidBy,
    amountCents: amount,
    date: date ?? DateTime(2026, 10, 1),
    shares: splitEqual(amount, participants),
  );
}

BalanceSettlement settlement(String from, String to, int cents, {DateTime? at}) {
  return BalanceSettlement(
    from: from,
    to: to,
    cents: cents,
    createdAt: at ?? DateTime(2026, 10, 2),
  );
}

void main() {
  group('calculateBalances', () {
    test('payer who also takes part: paid minus own share', () {
      final balances = calculateBalances(
        expenses: [expense('a', 1000, ['a', 'b', 'c'])],
        settlements: [],
      );
      expect(balances, {'a': 666, 'b': -333, 'c': -333});
      expect(balancesAddUp(balances), isTrue);
    });

    test('payer who does not take part is owed the full amount', () {
      final balances = calculateBalances(
        expenses: [expense('a', 1000, ['b', 'c'])],
        settlements: [],
      );
      expect(balances, {'a': 1000, 'b': -500, 'c': -500});
    });

    test('a settlement moves the balance from payer to receiver', () {
      final balances = calculateBalances(
        expenses: [expense('a', 1000, ['a', 'b', 'c'])],
        settlements: [settlement('b', 'a', 333)],
      );
      expect(balances, {'a': 333, 'b': 0, 'c': -333});
      expect(balancesAddUp(balances), isTrue);
    });

    test('a full settlement cancels the debt', () {
      final balances = calculateBalances(
        expenses: [expense('a', 2000, ['a', 'b'])],
        settlements: [settlement('b', 'a', 1000)],
      );
      expect(balances, {'a': 0, 'b': 0});
    });

    test('members without any activity are listed with 0', () {
      final balances = calculateBalances(
        expenses: [expense('a', 1000, ['a', 'b'])],
        settlements: [],
        memberIds: ['a', 'b', 'c'],
      );
      expect(balances['c'], 0);
      expect(balances.length, 3);
    });

    test('former members stay in the result while they have activity', () {
      // "x" left the group (not in memberIds) but is still on an expense.
      final balances = calculateBalances(
        expenses: [expense('a', 1000, ['a', 'x'])],
        settlements: [],
        memberIds: ['a', 'b'],
      );
      expect(balances, {'a': 500, 'b': 0, 'x': -500});
    });

    test('no data gives an empty result', () {
      expect(calculateBalances(expenses: [], settlements: []), isEmpty);
    });

    test('until: later expenses and settlements are ignored', () {
      final balances = calculateBalances(
        expenses: [
          expense('a', 1000, ['a', 'b'], date: DateTime(2026, 9, 30)),
          expense('a', 4000, ['a', 'b'], date: DateTime(2026, 10, 1)),
        ],
        settlements: [
          settlement('b', 'a', 500, at: DateTime(2026, 9, 30, 12)),
          settlement('b', 'a', 2000, at: DateTime(2026, 10, 1, 9)),
        ],
        until: DateTime(2026, 9, 30, 23, 59, 59),
      );
      // Only 10,00 EUR split in two and the 5,00 EUR settlement count.
      expect(balances, {'a': 0, 'b': 0});
    });

    test('until includes things from the last day itself', () {
      final balances = calculateBalances(
        expenses: [expense('a', 1000, ['a', 'b'], date: DateTime(2026, 9, 30))],
        settlements: [],
        until: DateTime(2026, 9, 30, 23, 59, 59),
      );
      expect(balances, {'a': 500, 'b': -500});
    });

    test('random data always adds up to zero', () {
      final random = Random(7);
      final users = ['u1', 'u2', 'u3', 'u4', 'u5'];
      for (var round = 0; round < 200; round++) {
        final expenses = <BalanceExpense>[];
        for (var i = 0; i < 1 + random.nextInt(12); i++) {
          final participants = users.where((_) => random.nextBool()).toList();
          if (participants.isEmpty) continue;
          expenses.add(expense(users[random.nextInt(5)], 1 + random.nextInt(99999), participants));
        }
        final settlements = <BalanceSettlement>[];
        for (var i = 0; i < random.nextInt(5); i++) {
          final from = users[random.nextInt(5)];
          final to = users[(users.indexOf(from) + 1 + random.nextInt(4)) % 5];
          settlements.add(settlement(from, to, 1 + random.nextInt(5000)));
        }
        final balances = calculateBalances(expenses: expenses, settlements: settlements);
        expect(balancesAddUp(balances), isTrue, reason: 'round $round');
      }
    });
  });

  group('balancesAddUp', () {
    test('detects inconsistent data (shares not matching the amount)', () {
      final broken = BalanceExpense(
        paidBy: 'a',
        amountCents: 1000,
        date: DateTime(2026, 10, 1),
        shares: const [ExpenseShare('a', 400), ExpenseShare('b', 500)],
      );
      final balances = calculateBalances(expenses: [broken], settlements: []);
      expect(balancesAddUp(balances), isFalse);
    });
  });
}
