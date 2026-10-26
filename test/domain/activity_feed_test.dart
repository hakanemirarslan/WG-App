import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/activity_feed.dart';

void main() {
  final monday = DateTime.utc(2026, 10, 26, 9);

  group('recentActivity', () {
    test('merges all kinds newest first', () {
      final result = recentActivity([
        Activity(ActivityKind.expense, 'e1', monday),
        Activity(ActivityKind.settlement, 's1', monday.add(const Duration(hours: 2))),
        Activity(ActivityKind.bought, 'b1', monday.add(const Duration(hours: 1))),
      ]);
      expect(result.map((a) => a.sourceId), ['s1', 'b1', 'e1']);
    });

    test('keeps only the newest [limit] entries', () {
      final many = [
        for (var i = 0; i < 8; i++)
          Activity(ActivityKind.expense, 'e$i', monday.add(Duration(minutes: i))),
      ];
      expect(recentActivity(many, limit: 3).map((a) => a.sourceId), ['e7', 'e6', 'e5']);
      expect(recentActivity(many).length, 5);
    });

    test('equal times are ordered by kind, then id (stable between rebuilds)', () {
      final result = recentActivity([
        Activity(ActivityKind.settlement, 's1', monday),
        Activity(ActivityKind.expense, 'e2', monday),
        Activity(ActivityKind.expense, 'e1', monday),
        Activity(ActivityKind.bought, 'b1', monday),
      ]);
      expect(result.map((a) => a.sourceId), ['e1', 'e2', 'b1', 's1']);
    });

    test('empty input and a limit larger than the input', () {
      expect(recentActivity(const []), isEmpty);
      expect(recentActivity([Activity(ActivityKind.bought, 'b1', monday)], limit: 10).length, 1);
    });

    test('does not change the input list', () {
      final input = [
        Activity(ActivityKind.expense, 'old', monday),
        Activity(ActivityKind.expense, 'new', monday.add(const Duration(days: 1))),
      ];
      recentActivity(input);
      expect(input.map((a) => a.sourceId), ['old', 'new']);
    });
  });
}
