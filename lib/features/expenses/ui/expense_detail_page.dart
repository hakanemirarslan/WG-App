import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets.dart';
import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/providers/groups_providers.dart';
import '../../groups/ui/group_error_text.dart';
import '../providers/expenses_providers.dart';

/// Expense detail (SPEC 11, screen 4) with edit and delete for the creator or an admin.
class ExpenseDetailPage extends ConsumerWidget {
  const ExpenseDetailPage({super.key, required this.groupId, required this.expenseId});

  final String groupId;
  final String expenseId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteExpenseConfirmTitle),
        content: Text(l10n.deleteExpenseConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(expensesRepositoryProvider).deleteExpense(expenseId);
      ref.invalidate(expensesProvider(groupId));
      if (context.mounted) context.pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(groupErrorText(l10n, error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final expensesAsync = ref.watch(expensesProvider(groupId));
    final members = ref.watch(groupMembersProvider(groupId)).value ?? const [];
    final myId = supabase.auth.currentUser!.id;
    final iAmAdmin = members.any((m) => m.userId == myId && m.isAdmin);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseDetailTitle)),
      body: expensesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) =>
            ErrorView(error: error, onRetry: () => ref.invalidate(expensesProvider(groupId))),
        data: (expenses) {
          final matches = expenses.where((e) => e.id == expenseId);
          // Deleted (e.g. by someone else) or not visible any more.
          if (matches.isEmpty) {
            return EmptyView(icon: Icons.receipt_long_outlined, message: l10n.expenseNotFound);
          }
          final expense = matches.first;
          final canModify = expense.createdBy == myId || iAmAdmin;

          final theme = Theme.of(context);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary: amount first, then what / when / who paid.
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatCents(expense.amountCents, locale: lang),
                            style: moneyStyle(theme.textTheme.displaySmall),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expense.displayTitle(lang) ?? l10n.defaultExpenseTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              InitialAvatar(name: expense.paidByName, radius: 14),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${l10n.paidByName(expense.paidByName)} · '
                                  '${DateFormat.yMMMd(lang).format(expense.date)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (expense.items.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final item in expense.items)
                                  Chip(label: Text(item.name.localized(lang))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SectionHeader(l10n.splitBetweenTitle),
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < expense.shares.length; i++) ...[
                          if (i > 0) const Divider(indent: 16, endIndent: 16),
                          ListTile(
                            leading: InitialAvatar(name: expense.shares[i].name),
                            title: Text(expense.shares[i].name),
                            trailing: Text(
                              formatCents(expense.shares[i].shareCents, locale: lang),
                              style: moneyStyle(theme.textTheme.bodyLarge),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canModify) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () =>
                                context.push('/group/$groupId/expenses/$expenseId/edit'),
                            label: Text(l10n.editButton),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            onPressed: () => _delete(context, ref),
                            label: Text(l10n.deleteExpenseButton),
                          ),
                        ),
                      ],
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
