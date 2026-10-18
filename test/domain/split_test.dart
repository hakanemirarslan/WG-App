import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/split.dart';

int sum(List<ExpenseShare> shares) =>
    shares.fold(0, (total, share) => total + share.shareCents);

void main() {
  group('splitEqual', () {
    test('10,00 EUR between 3 gives 334 / 333 / 333', () {
      expect(splitEqual(1000, ['a', 'b', 'c']), const [
        ExpenseShare('a', 334),
        ExpenseShare('b', 333),
        ExpenseShare('c', 333),
      ]);
    });

    test('leftover cents go to the first user ids, not the first in input order', () {
      expect(splitEqual(1000, ['c', 'a', 'b']), const [
        ExpenseShare('a', 334),
        ExpenseShare('b', 333),
        ExpenseShare('c', 333),
      ]);
    });

    test('two leftover cents go to the first two user ids', () {
      expect(splitEqual(1001, ['a', 'b', 'c']), const [
        ExpenseShare('a', 334),
        ExpenseShare('b', 334),
        ExpenseShare('c', 333),
      ]);
    });

    test('a single participant gets everything', () {
      expect(splitEqual(2350, ['a']), const [ExpenseShare('a', 2350)]);
    });

    test('1 cent between 3 people: only the first user id gets it', () {
      expect(splitEqual(1, ['a', 'b', 'c']), const [
        ExpenseShare('a', 1),
        ExpenseShare('b', 0),
        ExpenseShare('c', 0),
      ]);
    });

    test('shares always add up and differ by at most 1 cent', () {
      for (var amount = 1; amount <= 300; amount++) {
        for (var people = 1; people <= 8; people++) {
          final shares = splitEqual(amount, [for (var i = 0; i < people; i++) 'u$i']);
          expect(sum(shares), amount, reason: '$amount / $people');
          final values = shares.map((s) => s.shareCents);
          expect(values.reduce((a, b) => a > b ? a : b) - values.reduce((a, b) => a < b ? a : b),
              lessThanOrEqualTo(1));
        }
      }
    });

    test('rejects invalid input', () {
      expect(() => splitEqual(0, ['a']), throwsArgumentError);
      expect(() => splitEqual(-5, ['a']), throwsArgumentError);
      expect(() => splitEqual(100, []), throwsArgumentError);
      expect(() => splitEqual(100, ['a', 'a']), throwsArgumentError);
    });
  });

  group('splitByWeights', () {
    test('2:1:1 of 10,00 EUR gives 500 / 250 / 250', () {
      expect(splitByWeights(1000, {'a': 2, 'b': 1, 'c': 1}), const [
        ExpenseShare('a', 500),
        ExpenseShare('b', 250),
        ExpenseShare('c', 250),
      ]);
    });

    test('leftover cent goes to the first user id', () {
      // 100 * 2/3 = 66, 100 * 1/3 = 33, one cent left over.
      expect(splitByWeights(100, {'b': 1, 'a': 2}), const [
        ExpenseShare('a', 67),
        ExpenseShare('b', 33),
      ]);
    });

    test('same input in a different map order gives the same result', () {
      final first = splitByWeights(999, {'a': 3, 'b': 5, 'c': 7});
      final second = splitByWeights(999, {'c': 7, 'a': 3, 'b': 5});
      expect(first, second);
    });

    test('shares always add up to the amount', () {
      for (var amount = 1; amount <= 200; amount++) {
        final shares = splitByWeights(amount, {'a': 1, 'b': 2, 'c': 3, 'd': 5});
        expect(sum(shares), amount, reason: '$amount');
      }
    });

    test('handles the maximum amount without overflow', () {
      final shares = splitByWeights(10000000, {'a': 1, 'b': 3});
      expect(sum(shares), 10000000);
    });

    test('rejects zero or negative weights', () {
      expect(() => splitByWeights(100, {'a': 0, 'b': 1}), throwsArgumentError);
      expect(() => splitByWeights(100, {'a': -1}), throwsArgumentError);
    });
  });

  group('splitExact', () {
    test('accepts shares that add up to the amount', () {
      expect(splitExact(1000, {'b': 600, 'a': 400}), const [
        ExpenseShare('a', 400),
        ExpenseShare('b', 600),
      ]);
    });

    test('allows a participant with a 0 share', () {
      expect(sum(splitExact(500, {'a': 500, 'b': 0})), 500);
    });

    test('rejects shares that do not add up', () {
      expect(() => splitExact(1000, {'a': 400, 'b': 500}), throwsArgumentError);
      expect(() => splitExact(1000, {'a': 600, 'b': 500}), throwsArgumentError);
    });

    test('rejects negative shares', () {
      expect(() => splitExact(1000, {'a': 1200, 'b': -200}), throwsArgumentError);
    });
  });

  group('remainingCents', () {
    test('is positive while shares are missing, negative when over', () {
      expect(remainingCents(1000, {'a': 400}), 600);
      expect(remainingCents(1000, {'a': 400, 'b': 600}), 0);
      expect(remainingCents(1000, {'a': 700, 'b': 600}), -300);
    });
  });
}
