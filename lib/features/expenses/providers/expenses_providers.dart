import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../data/expenses_repository.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) => ExpensesRepository());

/// Live expense list: loads once, then reloads whenever Realtime reports a
/// change (same pattern as the shopping list). Balances in Hafta 5 are
/// computed from the same data.
final expensesProvider =
    StreamProvider.autoDispose.family<List<Expense>, String>((ref, groupId) {
  final repository = ref.watch(expensesRepositoryProvider);
  final controller = StreamController<List<Expense>>();

  Future<void> load() async {
    try {
      final expenses = await repository.fetchExpenses(groupId);
      if (!controller.isClosed) controller.add(expenses);
    } catch (error, stack) {
      if (!controller.isClosed) controller.addError(error, stack);
    }
  }

  load();
  final channel = repository.subscribe(groupId, load);
  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });
  return controller.stream;
});
