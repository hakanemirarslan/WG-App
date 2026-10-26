import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout.dart';
import '../../../core/error_view.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../domain/pair_debts.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../providers/balances_providers.dart';

/// Who owes whom for one person (opened from a member row on the Balance tab):
/// the net debt per counterpart, each expandable into the expenses and payments
/// behind it. The numbers come from `pairDebtsOf` (domain).
class PersonDebtsPage extends ConsumerWidget {
  const PersonDebtsPage({super.key, required this.groupId, required this.userId});

  final String groupId;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final balanceAsync = ref.watch(balancesProvider(groupId));
    final expenses = ref.watch(expensesProvider(groupId)).value;
    final settlements = ref.watch(settlementsProvider(groupId)).value;

    final data = balanceAsync.value;
    final name = data?.names[userId] ?? '';
    final isFormer = data != null && !data.activeMemberIds.contains(userId);

    Widget body() {
      if (balanceAsync.hasError) {
        return ErrorView(
          error: balanceAsync.error,
          onRetry: () {
            ref.invalidate(expensesProvider(groupId));
            ref.invalidate(settlementsProvider(groupId));
          },
        );
      }
      if (data == null || expenses == null || settlements == null) return const LoadingView();

      final debts = pairDebtsForUser(userId, expenses, settlements);
      final expensesById = {for (final e in expenses) e.id: e};
      final owes = debts.where((d) => d.cents > 0).toList();
      final isOwed = debts.where((d) => d.cents < 0).toList();

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PersonHeader(name: name, cents: data.balances[userId] ?? 0, lang: lang),
          if (debts.isEmpty)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.of(context).positive),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.allSettledUp)),
                  ],
                ),
              ),
            ),
          if (owes.isNotEmpty) ...[
            SectionHeader(l10n.personOwesTitle(name)),
            for (final debt in owes)
              _DebtCard(
                debt: debt,
                direction: 1,
                otherName: data.names[debt.otherId] ?? '',
                expensesById: expensesById,
                groupId: groupId,
                lang: lang,
              ),
          ],
          if (isOwed.isNotEmpty) ...[
            SectionHeader(l10n.personIsOwedTitle(name)),
            for (final debt in isOwed)
              _DebtCard(
                debt: debt,
                direction: -1,
                otherName: data.names[debt.otherId] ?? '',
                expensesById: expensesById,
                groupId: groupId,
                lang: lang,
              ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(isFormer ? '$name ${l10n.formerMemberSuffix}' : name)),
      body: ContentWidth(child: body()),
    );
  }
}

/// Avatar, name and the person's total balance.
class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.name, required this.cents, required this.lang});

  final String name;
  final int cents;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            InitialAvatar(name: name, radius: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(name, style: theme.textTheme.titleLarge)),
            DecoratedBox(
              decoration: BoxDecoration(
                color: balanceContainerColor(context, cents) ?? theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  formatCents(cents.abs(), locale: lang),
                  style: moneyStyle(
                    theme.textTheme.titleSmall?.copyWith(
                      color: onBalanceContainerColor(context, cents) ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One counterpart with the net amount; expands into the entries that add up to it.
/// [direction] is 1 in the "owes" section and -1 in the "is owed" section, so every
/// entry is shown from the point of view of that section (+ means "adds to this debt").
class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    required this.direction,
    required this.otherName,
    required this.expensesById,
    required this.groupId,
    required this.lang,
  });

  final PairDebt debt;
  final int direction;
  final String otherName;
  final Map<String, Expense> expensesById;
  final String groupId;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(lang);
    // The person owing money is shown on the coral pill, the one owed on the green pill.
    final pillColor = balanceContainerColor(context, -debt.cents);
    final onPillColor = onBalanceContainerColor(context, -debt.cents);

    return AppCard(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: InitialAvatar(name: otherName),
        title: Text(otherName),
        trailing: DecoratedBox(
          decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              formatCents(debt.cents.abs(), locale: lang),
              style: moneyStyle(theme.textTheme.titleSmall?.copyWith(color: onPillColor)),
            ),
          ),
        ),
        children: [
          for (final entry in debt.entries)
            Builder(
              builder: (context) {
                final expense = entry.source == DebtSource.expense
                    ? expensesById[entry.sourceId]
                    : null;
                final shown = entry.cents * direction;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    entry.source == DebtSource.settlement
                        ? l10n.settlementEntryLabel
                        : expense?.displayTitle(lang) ?? l10n.defaultExpenseTitle,
                  ),
                  subtitle: Text(dateFormat.format(entry.date)),
                  trailing: Text(
                    '${shown > 0 ? '+' : '−'}${formatCents(shown.abs(), locale: lang)}',
                    style: moneyStyle(theme.textTheme.bodyMedium),
                  ),
                  onTap: expense == null
                      ? null
                      : () => context.push('/group/$groupId/expenses/${expense.id}'),
                );
              },
            ),
        ],
      ),
    );
  }
}
