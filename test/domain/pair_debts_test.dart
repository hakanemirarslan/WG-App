import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/balance.dart';
import 'package:wg_app/domain/pair_debts.dart';
import 'package:wg_app/domain/split.dart';

BalanceExpense expense(
  String paidBy,
  int amount,
  List<String> participants, {
  String? id,
  DateTime? date,
}) {
  return BalanceExpense(
    id: id,
    paidBy: paidBy,
    amountCents: amount,
    date: date ?? DateTime(2026, 10, 1),
    shares: splitEqual(amount, participants),
  );
}

BalanceSettlement settlement(String from, String to, int cents, {String? id, DateTime? at}) {
  return BalanceSettlement(
    id: id,
    from: from,
    to: to,
    cents: cents,
    createdAt: at ?? DateTime(2026, 10, 2),
  );
}

Map<String, int> netByOther(List<PairDebt> debts) => {for (final d in debts) d.otherId: d.cents};

void main() {
  group('pairDebtsOf', () {
    test('payer is owed their friends\' shares, not their own', () {
      final expenses = [
        expense('a', 3000, ['a', 'b', 'c']),
      ];
      // Negative: the other person owes the user.
      expect(netByOther(pairDebtsOf('a', expenses: expenses, settlements: [])), {
        'b': -1000,
        'c': -1000,
      });
    });

    test('a participant owes the payer exactly their own share', () {
      final expenses = [
        expense('a', 3000, ['a', 'b', 'c']),
      ];
      expect(netByOther(pairDebtsOf('b', expenses: expenses, settlements: [])), {'a': 1000});
    });

    test('debts in both directions net out to one number per pair', () {
      final expenses = [
        expense('a', 1000, ['b']), // b owes a 10,00
        expense('b', 400, ['a']), // a owes b 4,00
      ];
      expect(netByOther(pairDebtsOf('b', expenses: expenses, settlements: [])), {'a': 600});
      expect(netByOther(pairDebtsOf('a', expenses: expenses, settlements: [])), {'b': -600});
    });

    test('a settlement reduces the debt of the sender and of the receiver view', () {
      final expenses = [
        expense('a', 2000, ['b']),
      ];
      final settlements = [settlement('b', 'a', 500)];
      expect(netByOther(pairDebtsOf('b', expenses: expenses, settlements: settlements)), {
        'a': 1500,
      });
      expect(netByOther(pairDebtsOf('a', expenses: expenses, settlements: settlements)), {
        'b': -1500,
      });
    });

    test('a fully settled pair disappears from the list', () {
      final expenses = [
        expense('a', 2000, ['b']),
      ];
      final settlements = [settlement('b', 'a', 2000)];
      expect(pairDebtsOf('b', expenses: expenses, settlements: settlements), isEmpty);
    });

    test('people without any shared expense are not listed', () {
      final expenses = [
        expense('a', 1000, ['a', 'b']),
        expense('c', 1000, ['c', 'd']),
      ];
      expect(netByOther(pairDebtsOf('a', expenses: expenses, settlements: [])), {'b': -500});
    });

    test('entries explain the sum, newest first, with their source ids', () {
      final expenses = [
        expense('a', 1000, ['b'], id: 'e1', date: DateTime(2026, 10, 1)),
        expense('a', 600, ['b'], id: 'e2', date: DateTime(2026, 10, 5)),
      ];
      final settlements = [settlement('b', 'a', 300, id: 's1', at: DateTime(2026, 10, 3))];
      final debt = pairDebtsOf('b', expenses: expenses, settlements: settlements).single;

      expect(debt.cents, 1300);
      expect(debt.entries.map((e) => e.sourceId), ['e2', 's1', 'e1']);
      expect(debt.entries.map((e) => e.source), [
        DebtSource.expense,
        DebtSource.settlement,
        DebtSource.expense,
      ]);
      // Positive adds to what b owes a, negative reduces it.
      expect(debt.entries.map((e) => e.cents), [600, -300, 1000]);
      expect(debt.entries.fold(0, (sum, e) => sum + e.cents), debt.cents);
    });

    test('result is sorted by size, ties by user id', () {
      final expenses = [
        expense('a', 1000, ['b']),
        expense('a', 3000, ['c']),
        expense('a', 1000, ['d']),
      ];
      final debts = pairDebtsOf('a', expenses: expenses, settlements: []);
      expect(debts.map((d) => d.otherId), ['c', 'b', 'd']);
    });

    test('random data: the pair debts always add up to minus the balance', () {
      final random = Random(7);
      const users = ['a', 'b', 'c', 'd', 'e'];
      for (var round = 0; round < 200; round++) {
        final expenses = [
          for (var i = 0; i < 1 + random.nextInt(8); i++)
            () {
              final participants = ([
                ...users,
              ]..shuffle(random)).take(1 + random.nextInt(5)).toList();
              return expense(
                users[random.nextInt(users.length)],
                100 + random.nextInt(20000),
                participants,
              );
            }(),
        ];
        final settlements = [
          for (var i = 0; i < random.nextInt(4); i++)
            () {
              final from = users[random.nextInt(users.length)];
              final to = users[(users.indexOf(from) + 1 + random.nextInt(4)) % users.length];
              return settlement(from, to, 1 + random.nextInt(5000));
            }(),
        ];
        final balances = calculateBalances(expenses: expenses, settlements: settlements);
        for (final user in users) {
          final owed = pairDebtsOf(
            user,
            expenses: expenses,
            settlements: settlements,
          ).fold(0, (sum, d) => sum + d.cents);
          expect(owed, -(balances[user] ?? 0), reason: 'round $round, user $user');
        }
      }
    });
  });
}
