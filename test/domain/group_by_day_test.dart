import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/group_by_day.dart';

void main() {
  DateTime at(int d, [int hour = 0]) => DateTime(2026, 10, d, hour);
  DateTime key(DateTime v) => v;

  test('empty input gives no groups', () {
    expect(groupByDay<DateTime>([], key), isEmpty);
  });

  test('items on the same day share one group, order is kept', () {
    final groups = groupByDay([at(5, 9), at(5, 18), at(4)], key);
    expect(groups, hasLength(2));
    expect(groups[0].day, DateTime(2026, 10, 5));
    expect(groups[0].items, [at(5, 9), at(5, 18)]);
    expect(groups[1].day, DateTime(2026, 10, 4));
    expect(groups[1].items, [at(4)]);
  });

  test('a day that reappears later starts a new group instead of merging', () {
    final groups = groupByDay([at(5), at(4), at(5)], key);
    expect(groups.map((g) => g.day.day), [5, 4, 5]);
  });

  test('works across month and year boundaries', () {
    final groups = groupByDay([DateTime(2027, 1, 1), DateTime(2026, 12, 31)], key);
    expect(groups, hasLength(2));
    expect(groups[0].day, DateTime(2027, 1, 1));
    expect(groups[1].day, DateTime(2026, 12, 31));
  });
}
