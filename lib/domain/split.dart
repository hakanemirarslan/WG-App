/// Expense splitting (SPEC 3). Pure Dart: no Flutter or Supabase imports.
/// All amounts are `int` cents. Every function returns shares sorted by
/// user id, so the same input always produces the same output.
library;

class ExpenseShare {
  final String userId;
  final int shareCents;

  const ExpenseShare(this.userId, this.shareCents);

  @override
  bool operator ==(Object other) =>
      other is ExpenseShare && other.userId == userId && other.shareCents == shareCents;

  @override
  int get hashCode => Object.hash(userId, shareCents);

  @override
  String toString() => 'ExpenseShare($userId, $shareCents)';
}

/// Equal split between [userIds].
List<ExpenseShare> splitEqual(int amountCents, Iterable<String> userIds) {
  final ids = userIds.toList();
  if (ids.toSet().length != ids.length) {
    throw ArgumentError('Duplicate participants');
  }
  return splitByWeights(amountCents, {for (final id in ids) id: 1});
}

/// Split by integer weights (e.g. 2:1:1).
///
/// Rounding (SPEC 3): everyone first gets `floor(amount * weight / totalWeight)`;
/// the leftover cents go one by one to the participants in user id order,
/// starting from the first.
List<ExpenseShare> splitByWeights(int amountCents, Map<String, int> weights) {
  if (amountCents <= 0) throw ArgumentError('Amount must be positive');
  if (weights.isEmpty) throw ArgumentError('At least one participant is required');
  if (weights.values.any((weight) => weight <= 0)) {
    throw ArgumentError('Weights must be positive');
  }

  final userIds = weights.keys.toList()..sort();
  final totalWeight = weights.values.fold(0, (sum, weight) => sum + weight);

  final shares = [
    for (final id in userIds) amountCents * weights[id]! ~/ totalWeight,
  ];
  var leftover = amountCents - shares.fold(0, (sum, share) => sum + share);
  for (var i = 0; leftover > 0; i++, leftover--) {
    shares[i] += 1;
  }

  return [for (var i = 0; i < userIds.length; i++) ExpenseShare(userIds[i], shares[i])];
}

/// Cents still to be assigned in "amount" mode; 0 means the shares add up.
int remainingCents(int amountCents, Map<String, int> shares) {
  return amountCents - shares.values.fold(0, (sum, share) => sum + share);
}

/// Validates user-entered amounts (SPEC 3, "Tutar" mode): none negative and
/// the total must equal [amountCents].
List<ExpenseShare> splitExact(int amountCents, Map<String, int> shares) {
  if (amountCents <= 0) throw ArgumentError('Amount must be positive');
  if (shares.isEmpty) throw ArgumentError('At least one participant is required');
  if (shares.values.any((share) => share < 0)) {
    throw ArgumentError('Shares must not be negative');
  }
  if (remainingCents(amountCents, shares) != 0) {
    throw ArgumentError('Shares must add up to the amount');
  }

  final userIds = shares.keys.toList()..sort();
  return [for (final id in userIds) ExpenseShare(id, shares[id]!)];
}
