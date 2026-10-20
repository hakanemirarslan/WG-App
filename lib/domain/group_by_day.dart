/// Items that fall on the same calendar [day].
class DayGroup<T> {
  const DayGroup(this.day, this.items);

  /// Midnight of the day, without time of day.
  final DateTime day;
  final List<T> items;
}

/// Splits [items] into runs of the same calendar day, keeping the input order.
/// The list is expected to be sorted already (the expenses list is newest
/// first); a day that appears again later in an unsorted list gets its own group.
List<DayGroup<T>> groupByDay<T>(List<T> items, DateTime Function(T item) dateOf) {
  final groups = <DayGroup<T>>[];
  for (final item in items) {
    final date = dateOf(item);
    final day = DateTime(date.year, date.month, date.day);
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.items.add(item);
    } else {
      groups.add(DayGroup(day, [item]));
    }
  }
  return groups;
}
