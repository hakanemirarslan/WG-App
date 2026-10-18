import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorGeneric)),
        data: (expenses) {
          final matches = expenses.where((e) => e.id == expenseId);
          // Deleted (e.g. by someone else) or not visible any more.
          if (matches.isEmpty) return Center(child: Text(l10n.errorGeneric));
          final expense = matches.first;
          final canModify = expense.createdBy == myId || iAmAdmin;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                formatCents(expense.amountCents, locale: lang),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                expense.displayTitle(lang) ?? l10n.defaultExpenseTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat.yMMMd(lang).format(expense.date)} · '
                '${l10n.paidByName(expense.paidByName)}',
              ),
              const Divider(height: 32),
              Text(l10n.splitBetweenTitle, style: Theme.of(context).textTheme.titleSmall),
              for (final share in expense.shares)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(share.name),
                  trailing: Text(formatCents(share.shareCents, locale: lang)),
                ),
              if (canModify) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/group/$groupId/expenses/$expenseId/edit'),
                  label: Text(l10n.editButton),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _delete(context, ref),
                  label: Text(l10n.deleteExpenseButton),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
