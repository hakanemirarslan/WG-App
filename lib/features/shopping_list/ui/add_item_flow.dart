import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/limits.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/providers/catalog_providers.dart';
import '../../catalog/ui/product_picker_sheet.dart';
import '../../groups/ui/group_error_text.dart';
import '../data/shopping_repository.dart';
import '../providers/shopping_providers.dart';

/// "Add item" (SPEC 7): pick a product, then an optional note. Used by the List tab
/// and by the overview tab.
Future<void> addShoppingItemFlow(BuildContext context, WidgetRef ref, String groupId) async {
  final l10n = AppLocalizations.of(context)!;
  final catalogRepository = ref.read(catalogRepositoryProvider);
  final picked = await showProductPicker(context, groupId);
  if (picked == null || !context.mounted) return;

  try {
    final groupItemId = await catalogRepository.getOrCreateGroupItem(
      groupId,
      catalogItemId: picked.catalogItemId,
      customName: picked.customName,
    );

    // Same product already open on the list: point to it instead of adding a copy.
    final entries = ref.read(shoppingEntriesProvider(groupId)).value ?? const [];
    final hidden = ref.read(pendingDeletionsProvider);
    final existing = entries.where(
      (e) => !e.isBought && e.groupItemId == groupItemId && !hidden.contains(e.id),
    );
    if (existing.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.alreadyOnList(existing.first.addedByName),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final note = await _askNote(context);
    if (note == null) return;

    await ref
        .read(shoppingRepositoryProvider)
        .addEntry(groupId, groupItemId, note.isEmpty ? null : note);
    await catalogRepository.touchGroupItem(groupItemId);
    ref.invalidate(frequentItemsProvider(groupId));
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(groupErrorText(l10n, error))));
    }
  }
}

/// Deletes [entry] with a 10 second "Undo": the entry disappears at once and is only
/// deleted in the database when the bar closes without "Undo". Re-inserting after a
/// delete would instead make the deleter its adder and reopen a bought item.
Future<void> deleteWithUndo(
  BuildContext context,
  WidgetRef ref,
  ShoppingEntry entry,
  String lang,
) async {
  final l10n = AppLocalizations.of(context)!;
  // Read everything now: the page may be gone when the bar closes.
  final pending = ref.read(pendingDeletionsProvider.notifier);
  final repository = ref.read(shoppingRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);

  pending.hide(entry.id);
  messenger.hideCurrentSnackBar();
  final reason = await messenger
      .showSnackBar(
        SnackBar(
          content: Text(l10n.entryDeletedMessage(entry.name.localized(lang))),
          duration: const Duration(seconds: 10),
          // A bar with an action stays open by default; this one must close by itself.
          persist: false,
          action: SnackBarAction(label: l10n.undoAction, onPressed: () {}),
        ),
      )
      .closed;
  if (reason == SnackBarClosedReason.action) {
    pending.restore(entry.id);
    return;
  }
  try {
    await repository.deleteEntry(entry.id);
  } catch (error) {
    pending.restore(entry.id);
    messenger.showSnackBar(SnackBar(content: Text(groupErrorText(l10n, error))));
  }
}

/// Returns the note ('' for none) or null if the user cancelled.
Future<String?> _askNote(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.noteLabel, hintText: l10n.noteHint),
        inputFormatters: limitTo(maxNoteLength),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancelButton)),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(l10n.addToListButton),
        ),
      ],
    ),
  );
}
