/// "Recent activity" on the overview tab: expenses entered, items bought and payments
/// recorded, merged into one newest-first list. Pure Dart; the UI looks up the names
/// and amounts by [Activity.sourceId].
library;

enum ActivityKind { expense, bought, settlement }

class Activity {
  final ActivityKind kind;

  /// Id of the expense, shopping entry or settlement behind this line.
  final String sourceId;
  final DateTime at;

  const Activity(this.kind, this.sourceId, this.at);
}

/// The [limit] newest activities. Equal times are ordered by kind and id, so the
/// list does not jump around between rebuilds.
List<Activity> recentActivity(Iterable<Activity> activities, {int limit = 5}) {
  final sorted = [...activities]
    ..sort((a, b) {
      final byTime = b.at.compareTo(a.at);
      if (byTime != 0) return byTime;
      final byKind = a.kind.index.compareTo(b.kind.index);
      return byKind != 0 ? byKind : a.sourceId.compareTo(b.sourceId);
    });
  return sorted.take(limit).toList();
}
