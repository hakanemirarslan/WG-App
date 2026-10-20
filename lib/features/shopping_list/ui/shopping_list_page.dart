import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets.dart';
import '../../../core/supabase_client.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/providers/catalog_providers.dart';
import '../../catalog/ui/product_picker_sheet.dart';
import '../../groups/providers/groups_providers.dart';
import '../../groups/ui/group_error_text.dart';
import '../data/shopping_repository.dart';
import '../providers/shopping_providers.dart';

/// "List" tab (SPEC 11): open items on top, "Recently bought" below.
class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key, required this.groupId});

  final String groupId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
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
      final existing = entries.where((e) => !e.isBought && e.groupItemId == groupItemId);
      if (existing.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.alreadyOnList(existing.first.addedByName))));
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
      if (context.mounted) _showError(context, error);
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

  void _showError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(groupErrorText(l10n, error))));
  }

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final groupName = ref.watch(groupProvider(groupId)).value?.name ?? '';
    final entriesAsync = ref.watch(shoppingEntriesProvider(groupId));
    final members = ref.watch(groupMembersProvider(groupId)).value ?? const [];
    final myId = supabase.auth.currentUser!.id;
    final iAmAdmin = members.any((m) => m.userId == myId && m.isAdmin);
    final repository = ref.read(shoppingRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text(groupName),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addItemButton,
        onPressed: () => _add(context, ref),
        child: const Icon(Icons.add),
      ),
      body: entriesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(shoppingEntriesProvider(groupId)),
        ),
        data: (entries) {
          final open = entries.where((e) => !e.isBought).toList();
          final bought = entries.where((e) => e.isBought).toList()
            ..sort((a, b) => b.boughtAt!.compareTo(a.boughtAt!));

          Widget? deleteButton(ShoppingEntry entry) {
            if (entry.addedBy != myId && !iAmAdmin) return null;
            return IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteEntryAction,
              onPressed: () => _run(context, () => repository.deleteEntry(entry.id)),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              if (open.isEmpty)
                EmptyView(
                  icon: Icons.shopping_basket_outlined,
                  message: l10n.openItemsEmpty,
                  actionLabel: l10n.addItemButton,
                  onAction: () => _add(context, ref),
                ),
              for (final entry in open)
                AppCard(
                  child: ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.radio_button_unchecked),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: l10n.markBoughtTooltip,
                      onPressed: () => _run(context, () => repository.markBought(entry.id)),
                    ),
                    title: Text(entry.name.localized(lang)),
                    subtitle: Text(
                      [
                        if (entry.note != null) entry.note!,
                        l10n.addedByLabel(entry.addedByName),
                      ].join(' · '),
                    ),
                    trailing: deleteButton(entry),
                  ),
                ),
              if (bought.isNotEmpty) ...[
                SectionHeader(l10n.recentlyBoughtTitle),
                for (final entry in bought)
                  AppCard(
                    child: ListTile(
                      leading: IconButton(
                        icon: const Icon(Icons.undo),
                        tooltip: l10n.undoBoughtTooltip,
                        onPressed: () => _run(context, () => repository.undoBought(entry.id)),
                      ),
                      title: Text(
                        entry.name.localized(lang),
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      subtitle: Text(l10n.boughtByLabel(entry.boughtByName ?? '')),
                      trailing: deleteButton(entry),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
