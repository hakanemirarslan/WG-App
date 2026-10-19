import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets.dart';
import '../../../core/money.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/providers/groups_providers.dart';
import '../providers/expenses_providers.dart';

/// "Expenses" tab (SPEC 11): chronological list, newest first.
class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final groupName = ref.watch(groupProvider(groupId)).value?.name ?? '';
    final expensesAsync = ref.watch(expensesProvider(groupId));
    final dateFormat = DateFormat.yMMMd(lang);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text(groupName),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addExpenseButton,
        onPressed: () => context.push('/group/$groupId/expenses/new'),
        child: const Icon(Icons.add),
      ),
      body: expensesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) =>
            ErrorView(error: error, onRetry: () => ref.invalidate(expensesProvider(groupId))),
        data: (expenses) {
          if (expenses.isEmpty) {
            return EmptyView(message: l10n.expensesEmpty);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expensesProvider(groupId));
              await ref.read(expensesProvider(groupId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return AppCard(
                  child: ListTile(
                    title: Text(expense.displayTitle(lang) ?? l10n.defaultExpenseTitle),
                    subtitle: Text(
                      '${dateFormat.format(expense.date)} · ${l10n.paidByName(expense.paidByName)}',
                    ),
                    trailing: Text(
                      formatCents(expense.amountCents, locale: lang),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () => context.push('/group/$groupId/expenses/${expense.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
