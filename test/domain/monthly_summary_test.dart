import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/balance.dart';
import 'package:wg_app/domain/monthly_summary.dart';
import 'package:wg_app/domain/split.dart';

BalanceExpense expense(String paidBy, int amount, List<String> participants, DateTime date) {
  return BalanceExpense(
    paidBy: paidBy,
    amountCents: amount,
    date: date,
    shares: splitEqual(amount, participants),
  );
}

BalanceSettlement settlement(String from, String to, int cents, DateTime at) {
  return BalanceSettlement(from: from, to: to, cents: cents, createdAt: at);
}

void main() {
  group('summarizeMonth: which expenses belong to the month', () {
    final expenses = [
      expense('a', 1000, ['a', 'b'], DateTime(2026, 9, 30)),
      expense('a', 2000, ['a', 'b'], DateTime(2026, 10, 1)),
      expense('b', 3000, ['a', 'b'], DateTime(2026, 10, 31)),
      expense('a', 4000, ['a', 'b'], DateTime(2026, 11, 1)),
    ];

    test('includes the first and last day, excludes the neighbouring months', () {
      final summary = summarizeMonth(
        year: 2026,
        month: 10,
        expenses: expenses,
        settlements: [],
      );
      expect(summary.expenseCount, 2);
      expect(summary.totalCents, 5000);
    });

    test('an empty month has no totals', () {
      final summary = summarizeMonth(year: 2026, month: 8, expenses: expenses, settlements: []);
      expect(summary.expenseCount, 0);
      expect(summary.totalCents, 0);
      expect(summary.paidByUser, isEmpty);
    });

    test('December works across the year boundary', () {
      final summary = summarizeMonth(
        year: 2026,
        month: 12,
        expenses: [
          expense('a', 1000, ['a', 'b'], DateTime(2026, 12, 31)),
          expense('a', 9000, ['a', 'b'], DateTime(2027, 1, 1)),
        ],
        settlements: [],
      );
      expect(summary.totalCents, 1000);
    });
  });

  group('summarizeMonth: paid and share per person', () {
    test('adds up what each person paid and owes for the month', () {
      final summary = summarizeMonth(
        year: 2026,
        month: 10,
        expenses: [
          expense('a', 3000, ['a', 'b', 'c'], DateTime(2026, 10, 3)),
          expense('b', 1000, ['a', 'b', 'c'], DateTime(2026, 10, 4)),
        ],
        settlements: [],
      );
      expect(summary.paidByUser, {'a': 3000, 'b': 1000});
      // 1000 / 3 = 334 / 333 / 333, remainder to the first user id.
      expect(summary.shareByUser, {'a': 1334, 'b': 1333, 'c': 1333});
    });

    test('paid and share both add up to the month total', () {
      final summary = summarizeMonth(
        year: 2026,
        month: 10,
        expenses: [
          expense('a', 1001, ['a', 'b', 'c'], DateTime(2026, 10, 3)),
          expense('c', 777, ['b', 'c'], DateTime(2026, 10, 9)),
        ],
        settlements: [],
      );
      int sum(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);
      expect(sum(summary.paidByUser), summary.totalCents);
      expect(sum(summary.shareByUser), summary.totalCents);
    });
  });

  group('summarizeMonth: balance at the end of the month', () {
    final expenses = [
      expense('a', 1000, ['a', 'b'], DateTime(2026, 9, 15)), // a +500, b -500
      expense('a', 2000, ['a', 'b'], DateTime(2026, 10, 10)), // a +1000, b -1000
      expense('b', 6000, ['a', 'b'], DateTime(2026, 11, 5)), // later: ignored for October
    ];

    test('counts earlier months and the month itself, not later ones', () {
      final summary = summarizeMonth(
        year: 2026,
        month: 10,
        expenses: expenses,
        settlements: [],
      );
      expect(summary.endBalances, {'a': 1500, 'b': -1500});
    });

    test('settlements up to the end of the month reduce the balance', () {
      final summary = summarizeMonth(
        year: 2026,
        month: 10,
        expenses: expenses,
        settlements: [
          settlement('b', 'a', 500, DateTime(2026, 10, 20, 18)),
          settlement('b', 'a', 9999, DateTime(2026, 11, 2)), // after the month
        ],
      );
      expect(summary.endBalances, {'a': 1000, 'b': -1000});
    });

    test('a settlement late on the last day still counts', () {
      final summary = summarizeMonth(
        year: 2026,
        month: 10,
        expenses: expenses,
        settlements: [settlement('b', 'a', 500, DateTime(2026, 10, 31, 23, 59, 59))],
      );
      expect(summary.endBalances['a'], 1000);
    });

    test('lists members without activity with 0', () {
      final summary = summarizeMonth(
        year: 2026,
        month: 10,
        expenses: expenses,
        settlements: [],
        memberIds: ['a', 'b', 'c'],
      );
      expect(summary.endBalances['c'], 0);
    });
  });
}
