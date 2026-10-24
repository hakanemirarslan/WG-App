import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets.dart';
import '../../../core/money.dart';
import '../../../core/error_view.dart';
import '../../../domain/group_by_day.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/providers/groups_providers.dart';
import '../data/expenses_repository.dart';
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
    final dateFormat = DateFormat.yMMMEd(lang);

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
            return EmptyView(
              icon: Icons.receipt_long_outlined,
              message: l10n.expensesEmpty,
              actionLabel: l10n.addExpenseButton,
              onAction: () => context.push('/group/$groupId/expenses/new'),
            );
          }
          // One date header per day, followed by that day's expenses.
          final rows = <Object>[
            for (final group in groupByDay(expenses, (e) => e.date)) ...[group.day, ...group.items],
          ];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expensesProvider(groupId));
              await ref.read(expensesProvider(groupId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                if (row is DateTime) return SectionHeader(dateFormat.format(row));
                final expense = row as Expense;
                return FadeSlide(
                  // Rows are built lazily while scrolling, so cap the stagger: a late
                  // row must not wait seconds before it appears.
                  delay: Duration(milliseconds: math.min(index, 8) * 50),
                  child: AnimatedPressCard(
                    onTap: () => context.push('/group/$groupId/expenses/${expense.id}'),
                    child: ListTile(
                      // The avatar shows who paid; the subtitle repeats it in words.
                      leading: InitialAvatar(name: expense.paidByName),
                      title: Text(
                        expense.displayTitle(lang) ?? l10n.defaultExpenseTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(l10n.paidByName(expense.paidByName)),
                      trailing: Text(
                        formatCents(expense.amountCents, locale: lang),
                        style: moneyStyle(Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
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
