import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/money.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.errorGeneric),
              if (kDebugMode) SelectableText('$error'),
              TextButton(
                onPressed: () => ref.invalidate(expensesProvider(groupId)),
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.expensesEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expensesProvider(groupId));
              await ref.read(expensesProvider(groupId).future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: expenses.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ListTile(
                  title: Text(expense.displayTitle(lang) ?? l10n.defaultExpenseTitle),
                  subtitle: Text(
                    '${dateFormat.format(expense.date)} · ${l10n.paidByName(expense.paidByName)}',
                  ),
                  trailing: Text(
                    formatCents(expense.amountCents, locale: lang),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () => context.push('/group/$groupId/expenses/${expense.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
