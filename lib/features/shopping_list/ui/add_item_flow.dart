import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/image_viewer.dart';
import '../../../core/images.dart';
import '../../../core/limits.dart';
import '../../../domain/image_file.dart';
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
    final details = await showDialog<_EntryDetails>(
      context: context,
      builder: (context) => _EntryDetailsDialog(groupId: groupId),
    );
    if (details == null) return;

    try {
      await ref
          .read(shoppingRepositoryProvider)
          .addEntry(
            groupId,
            groupItemId,
            details.note.isEmpty ? null : details.note,
            photoPath: details.photoPath,
          );
    } catch (_) {
      // Nothing points to the uploaded photo: remove it again (SPEC 18).
      await ref.read(imageRepositoryProvider).remove([details.photoPath]);
      rethrow;
    }
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
  final images = ref.read(imageRepositoryProvider);
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
    return;
  }
  // The row is gone, so its photo may be deleted now (SPEC 18). Best effort.
  await images.remove([entry.photoPath]);
}

/// The optional details of a new entry: a note ('' for none) and a photo.
typedef _EntryDetails = ({String note, String? photoPath});

/// Note and optional photo for a new entry. The photo is uploaded as soon as it is
/// picked (so the preview shows the real file); cancelling, or picking another one,
/// deletes what was uploaded. Returns null if cancelled.
class _EntryDetailsDialog extends ConsumerStatefulWidget {
  const _EntryDetailsDialog({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_EntryDetailsDialog> createState() => _EntryDetailsDialogState();
}

class _EntryDetailsDialogState extends ConsumerState<_EntryDetailsDialog> {
  final _noteController = TextEditingController();
  String? _photoPath;
  bool _uploading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final images = ref.read(imageRepositoryProvider);
    try {
      final path = await pickAndUploadImage(
        context,
        ref,
        ImageKind.shoppingItem,
        widget.groupId,
        onPicked: () => setState(() => _uploading = true),
      );
      if (path == null) return;
      final previous = _photoPath;
      if (mounted) {
        setState(() => _photoPath = path);
      } else {
        await images.remove([path]); // dialog closed meanwhile
      }
      await images.remove([previous]);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final path = _photoPath;
    setState(() => _photoPath = null);
    await ref.read(imageRepositoryProvider).remove([path]);
  }

  void _cancel() {
    ref.read(imageRepositoryProvider).remove([_photoPath]);
    Navigator.pop(context);
  }

  void _submit() => Navigator.pop<_EntryDetails>(context, (
    note: _noteController.text.trim(),
    photoPath: _photoPath,
  ));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photo = _photoPath;
    return PopScope(
      // Closing by tapping outside or the back button counts as cancel.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_uploading) _cancel();
      },
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _noteController,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.noteLabel, hintText: l10n.noteHint),
              inputFormatters: limitTo(maxNoteLength),
              onSubmitted: (_) => _uploading ? null : _submit(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_uploading)
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (photo != null)
                  PhotoThumbnail(
                    path: photo,
                    size: 56,
                    onTap: () => showImageViewer(context, path: photo),
                  ),
                if (_uploading || photo != null) const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        onPressed: _uploading ? null : _pickPhoto,
                        label: Text(photo == null ? l10n.addPhotoButton : l10n.changePhotoButton),
                      ),
                      if (photo != null && !_uploading)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: _removePhoto,
                          label: Text(l10n.removePhotoButton),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: _uploading ? null : _cancel, child: Text(l10n.cancelButton)),
          FilledButton(onPressed: _uploading ? null : _submit, child: Text(l10n.addToListButton)),
        ],
      ),
    );
  }
}

/// Lets the adder or an admin add, change or remove the photo of an existing entry
/// (SPEC 18). Same order as everywhere: upload, point the row at it, delete the old.
Future<void> updateEntryPhoto(
  BuildContext context,
  WidgetRef ref,
  String groupId,
  ShoppingEntry entry, {
  bool remove = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final String? newPath;
    if (remove) {
      newPath = null;
    } else {
      newPath = await pickAndUploadImage(context, ref, ImageKind.shoppingItem, groupId);
      if (newPath == null) return;
    }
    await ref
        .read(imageRepositoryProvider)
        .replace(
          oldPath: entry.photoPath,
          newPath: newPath,
          save: (path) => ref.read(shoppingRepositoryProvider).setEntryPhoto(entry.id, path),
        );
    ref.invalidate(shoppingEntriesProvider(groupId));
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(groupErrorText(l10n, error))));
  }
}
