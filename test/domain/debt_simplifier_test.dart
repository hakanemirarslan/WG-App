import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/debt_simplifier.dart';
import 'package:wg_app/domain/split.dart';

/// Applies [transfers] to [balances]: the payer's balance goes up, the
/// receiver's goes down, exactly like a settlement (SPEC 4).
Map<String, int> applyTransfers(Map<String, int> balances, List<Transfer> transfers) {
  final result = Map<String, int>.of(balances);
  for (final t in transfers) {
    result[t.from] = result[t.from]! + t.cents;
    result[t.to] = result[t.to]! - t.cents;
  }
  return result;
}

void main() {
  group('simplifyDebts: required scenarios (SPEC 5)', () {
    test('1. empty or all-zero balances need no transfers', () {
      expect(simplifyDebts({}), isEmpty);
      expect(simplifyDebts({'a': 0, 'b': 0, 'c': 0}), isEmpty);
    });

    test('2. two people, one debt', () {
      expect(simplifyDebts({'a': 2000, 'b': -2000}), const [Transfer('b', 'a', 2000)]);
    });

    test('3. three people in a chain collapse into one transfer', () {
      // A owes B 10, B owes C 10: B is even, so A pays C directly.
      expect(simplifyDebts({'a': -1000, 'b': 0, 'c': 1000}), const [Transfer('a', 'c', 1000)]);
    });

    test('4. one creditor, three debtors', () {
      expect(simplifyDebts({'a': 3000, 'b': -1000, 'c': -1000, 'd': -1000}), const [
        Transfer('b', 'a', 1000),
        Transfer('c', 'a', 1000),
        Transfer('d', 'a', 1000),
      ]);
    });

    test('5. rounding leftovers (334 / 333 / 333) keep the total intact', () {
      // a paid 10,00 EUR split equally between a, b, c.
      final shares = splitEqual(1000, ['a', 'b', 'c']);
      final balances = {
        for (final s in shares) s.userId: (s.userId == 'a' ? 1000 : 0) - s.shareCents,
      };
      expect(balances, {'a': 666, 'b': -333, 'c': -333});

      final transfers = simplifyDebts(balances);
      expect(transfers, const [Transfer('b', 'a', 333), Transfer('c', 'a', 333)]);
      expect(applyTransfers(balances, transfers).values, everyElement(0));
    });

    test('6. large random sets: at most n-1 transfers and everything settles', () {
      final random = Random(42);
      for (var round = 0; round < 300; round++) {
        final n = 2 + random.nextInt(11);
        final users = [for (var i = 0; i < n; i++) 'user${i.toString().padLeft(2, '0')}'];

        // Build balances from real expenses so the sum is 0 by construction.
        final balances = {for (final u in users) u: 0};
        for (var e = 0; e < 1 + random.nextInt(15); e++) {
          final amount = 1 + random.nextInt(50000);
          final payer = users[random.nextInt(n)];
          final participants = users.where((_) => random.nextBool()).toList();
          if (participants.isEmpty) continue;
          balances[payer] = balances[payer]! + amount;
          for (final s in splitEqual(amount, participants)) {
            balances[s.userId] = balances[s.userId]! - s.shareCents;
          }
        }
        expect(balances.values.fold(0, (a, b) => a + b), 0);

        final transfers = simplifyDebts(balances);
        expect(transfers.length, lessThanOrEqualTo(n - 1), reason: 'round $round');
        expect(transfers.every((t) => t.cents > 0 && t.from != t.to), isTrue);
        expect(applyTransfers(balances, transfers).values, everyElement(0),
            reason: 'round $round');
      }
    });
  });

  group('simplifyDebts: behaviour', () {
    test('matches the largest debtor with the largest creditor, re-sorting after each transfer', () {
      expect(simplifyDebts({'a': 700, 'b': 300, 'c': -600, 'd': -400}), const [
        Transfer('c', 'a', 600),
        Transfer('d', 'b', 300),
        Transfer('d', 'a', 100),
      ]);
    });

    test('ties are broken by user id, so the result is deterministic', () {
      final first = simplifyDebts({'b': 500, 'a': 500, 'd': -500, 'c': -500});
      final second = simplifyDebts({'c': -500, 'a': 500, 'd': -500, 'b': 500});
      expect(first, second);
      expect(first, const [Transfer('c', 'a', 500), Transfer('d', 'b', 500)]);
    });

    test('rejects balances that do not add up to zero', () {
      expect(() => simplifyDebts({'a': 100, 'b': -50}), throwsArgumentError);
    });
  });
}
