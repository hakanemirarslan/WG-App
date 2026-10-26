import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../data/shopping_repository.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) => ShoppingRepository());

/// Entries the user just deleted: hidden at once, removed from the database only when
/// the "Undo" bar closes without being used (see `deleteWithUndo`). Not auto-disposed,
/// so a pending deletion survives switching tabs.
class PendingDeletions extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void hide(String entryId) => state = {...state, entryId};

  void restore(String entryId) => state = {...state}..remove(entryId);
}

final pendingDeletionsProvider = NotifierProvider<PendingDeletions, Set<String>>(
  PendingDeletions.new,
);

/// Live shopping list: loads once, then reloads whenever Realtime reports a
/// change (including our own). Reloading instead of patching from the stream
/// payload keeps the joined names (item, adder, buyer) correct.
final shoppingEntriesProvider = StreamProvider.autoDispose.family<List<ShoppingEntry>, String>((
  ref,
  groupId,
) {
  final repository = ref.watch(shoppingRepositoryProvider);
  final controller = StreamController<List<ShoppingEntry>>();

  Future<void> load() async {
    try {
      final entries = await repository.fetchEntries(groupId);
      if (!controller.isClosed) controller.add(entries);
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
