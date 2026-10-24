import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets.dart';
import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
import '../../../core/error_view.dart';
import '../../../domain/split.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/providers/catalog_providers.dart';
import '../../catalog/ui/product_picker_sheet.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../groups/providers/groups_providers.dart';
import '../../groups/ui/group_error_text.dart';
import '../data/shopping_repository.dart';
import '../providers/shopping_providers.dart';
import 'bought_price_dialog.dart';

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

  /// "Bought": asks for an optional price. With a price the item is also saved as an
  /// expense paid by me and split equally between all active members; without one
  /// it is only ticked off.
  ///
  /// There is no transaction across the two tables, so the entry is marked first and
  /// rolled back (put back on the list) if the expense cannot be saved. That way a
  /// failure leaves the list as it was and the user can simply try again. Only if the
  /// rollback fails too does the item stay ticked off, and the user is told so.
  Future<void> _markBought(
    BuildContext context,
    WidgetRef ref,
    ShoppingEntry entry,
    String lang,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cents = await showBoughtPriceDialog(context, entry.name.localized(lang));
    if (cents == null || !context.mounted) return;

    final shopping = ref.read(shoppingRepositoryProvider);
    try {
      await shopping.markBought(entry.id);
    } catch (error) {
      if (context.mounted) _showError(context, error);
      return;
    }
    if (cents == 0) return;

    final expenses = ref.read(expensesRepositoryProvider);
    String? expenseId;
    String message;
    try {
      final members = await ref.read(groupMembersProvider(groupId).future);
      expenseId = await expenses.saveExpense(
        groupId: groupId,
        paidBy: supabase.auth.currentUser!.id,
        amountCents: cents,
        date: DateTime.now(),
        shares: splitEqual(cents, members.map((m) => m.userId)),
        itemIds: [entry.groupItemId],
      );
      // Remember the expense so that undoing "bought" can delete it again.
      await shopping.linkExpense(entry.id, expenseId);
      message = l10n.boughtExpenseRecorded(formatCents(cents, locale: lang));
    } catch (_) {
      try {
        // Remove a half-finished expense too, then put the item back on the list.
        if (expenseId != null && !await expenses.tryDeleteExpense(expenseId)) {
          throw StateError('expense $expenseId could not be removed');
        }
        await shopping.undoBought(entry.id);
        message = l10n.boughtExpenseFailedKeptOpen;
      } catch (_) {
        message = l10n.boughtExpenseFailedTickedOff;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Puts a bought item back on the list. If its price created an expense, that expense
  /// is deleted as well (after a confirmation), so Expenses and Balance stay correct.
  Future<void> _undoBought(BuildContext context, WidgetRef ref, ShoppingEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final expenseId = entry.expenseId;

    if (expenseId != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.undoBoughtConfirmTitle),
          content: Text(l10n.undoBoughtDeletesExpense),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.undoBoughtConfirmButton),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    await _run(context, () async {
      if (expenseId != null) {
        final deleted = await ref.read(expensesRepositoryProvider).tryDeleteExpense(expenseId);
        if (!deleted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.undoBoughtExpenseNotAllowed)));
          }
          return;
        }
      }
      await ref.read(shoppingRepositoryProvider).undoBought(entry.id);
    });
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

          final theme = Theme.of(context);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                children: [
                  if (open.isEmpty)
                    EmptyView(
                      icon: Icons.shopping_basket_outlined,
                      message: l10n.openItemsEmpty,
                      actionLabel: l10n.addItemButton,
                      onAction: () => _add(context, ref),
                    )
                  else
                    // One card for all open items, thin dividers between the rows.
                    AppCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < open.length; i++) ...[
                            if (i > 0) const Divider(indent: 16, endIndent: 16),
                            ListTile(
                              leading: IconButton(
                                icon: const Icon(Icons.radio_button_unchecked),
                                color: theme.colorScheme.primary,
                                tooltip: l10n.markBoughtTooltip,
                                onPressed: () => _markBought(context, ref, open[i], lang),
                              ),
                              title: Text(open[i].name.localized(lang)),
                              subtitle: Text(
                                [
                                  if (open[i].note != null) open[i].note!,
                                  l10n.addedByLabel(open[i].addedByName),
                                ].join(' · '),
                              ),
                              trailing: deleteButton(open[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (bought.isNotEmpty) ...[
                    SectionHeader(l10n.recentlyBoughtTitle),
                    AppCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < bought.length; i++) ...[
                            if (i > 0) const Divider(indent: 16, endIndent: 16),
                            ListTile(
                              leading: IconButton(
                                icon: const Icon(Icons.undo),
                                tooltip: l10n.undoBoughtTooltip,
                                onPressed: () => _undoBought(context, ref, bought[i]),
                              ),
                              title: Text(
                                bought[i].name.localized(lang),
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              subtitle: Text(l10n.boughtByLabel(bought[i].boughtByName ?? '')),
                              trailing: deleteButton(bought[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
