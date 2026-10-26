import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error_view.dart';
import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../domain/activity_feed.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/data/settlements_repository.dart';
import '../../balances/providers/balances_providers.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../groups/providers/groups_providers.dart';
import '../../settings/providers/profile_providers.dart';
import '../../shopping_list/data/shopping_repository.dart';
import '../../shopping_list/providers/shopping_providers.dart';
import '../../shopping_list/ui/add_item_flow.dart';

/// "Overview" tab, the first tab of a group: my balance, what is on the list and what
/// happened recently. Everything comes from the providers the other tabs already use.
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key, required this.groupId});

  final String groupId;

  static const _previewItems = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final groupName = ref.watch(groupProvider(groupId)).value?.name ?? '';
    final myName = ref.watch(myProfileProvider).value?.displayName;
    final balanceAsync = ref.watch(balancesProvider(groupId));
    final entriesAsync = ref.watch(shoppingEntriesProvider(groupId));
    final expenses = ref.watch(expensesProvider(groupId)).value;
    final settlements = ref.watch(settlementsProvider(groupId)).value;
    final myId = supabase.auth.currentUser!.id;

    Widget body() {
      final error = balanceAsync.error ?? entriesAsync.error;
      if (error != null) {
        return ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(expensesProvider(groupId));
            ref.invalidate(settlementsProvider(groupId));
            ref.invalidate(shoppingEntriesProvider(groupId));
          },
        );
      }
      final balances = balanceAsync.value;
      final entries = entriesAsync.value;
      if (balances == null || entries == null || expenses == null || settlements == null) {
        return const LoadingView();
      }

      final open = entries.where((e) => !e.isBought).toList();
      final bought = entries.where((e) => e.isBought && e.boughtAt != null);
      final activity = recentActivity([
        for (final e in expenses) Activity(ActivityKind.expense, e.id, e.createdAt),
        for (final e in bought) Activity(ActivityKind.bought, e.id, e.boughtAt!),
        for (final s in settlements) Activity(ActivityKind.settlement, s.id, s.createdAt),
      ]);
      final expensesById = {for (final e in expenses) e.id: e};
      final entriesById = {for (final e in entries) e.id: e};
      final settlementsById = {for (final s in settlements) s.id: s};
      final theme = Theme.of(context);

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (myName != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text(l10n.greeting(myName), style: theme.textTheme.headlineSmall),
                ),
              _BalanceCard(
                cents: balances.balances[myId] ?? 0,
                lang: lang,
                onTap: () => context.go('/group/$groupId/balance'),
              ),
              _SectionRow(
                title: l10n.openItemsCount(open.length),
                actionLabel: open.isEmpty ? null : l10n.seeAllAction,
                onAction: () => context.go('/group/$groupId/list'),
              ),
              AppCard(
                child: Column(
                  children: [
                    for (final entry in open.take(_previewItems)) ...[
                      ListTile(
                        leading: Icon(
                          Icons.radio_button_unchecked,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(entry.name.localized(lang)),
                        subtitle: entry.note == null ? null : Text(entry.note!),
                        onTap: () => context.go('/group/$groupId/list'),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                    ],
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: Text(l10n.addItemButton),
                      textColor: theme.colorScheme.primary,
                      iconColor: theme.colorScheme.primary,
                      onTap: () => addShoppingItemFlow(context, ref, groupId),
                    ),
                  ],
                ),
              ),
              SectionHeader(l10n.recentActivityTitle),
              if (activity.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.noActivityYet,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < activity.length; i++) ...[
                        if (i > 0) const Divider(indent: 16, endIndent: 16),
                        _ActivityTile(
                          activity: activity[i],
                          expenses: expensesById,
                          entries: entriesById,
                          settlements: settlementsById,
                          groupId: groupId,
                          lang: lang,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text(groupName),
      ),
      body: body(),
    );
  }
}

/// My balance in this group, tappable to open the Balance tab.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.cents, required this.lang, required this.onTap});

  final int cents;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final amountColor = cents > 0
        ? colors.positive
        : cents < 0
        ? colors.negative
        : theme.colorScheme.onSurface;
    final status = cents > 0
        ? l10n.youAreOwedStatus
        : cents < 0
        ? l10n.youOweStatus
        : l10n.allSettledUp;
    final sign = cents > 0 ? '+' : (cents < 0 ? '−' : '');

    return AnimatedPressCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.yourBalanceLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sign${formatCents(cents.abs(), locale: lang)}',
                    style: moneyStyle(theme.textTheme.headlineMedium?.copyWith(color: amountColor)),
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          balanceContainerColor(context, cents) ??
                          theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        status,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color:
                              onBalanceContainerColor(context, cents) ??
                              theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Section heading with an optional text button on the right ("See all").
class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.title, this.actionLabel, required this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SectionHeader(title)),
        if (actionLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
      ],
    );
  }
}

/// One line of the activity feed: who did what, the amount if any, and when.
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.expenses,
    required this.entries,
    required this.settlements,
    required this.groupId,
    required this.lang,
  });

  final Activity activity;
  final Map<String, Expense> expenses;
  final Map<String, ShoppingEntry> entries;
  final Map<String, Settlement> settlements;
  final String groupId;
  final String lang;

  String _when(AppLocalizations l10n, DateTime at) {
    final local = at.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(local);
    if (day == today) return l10n.todayLabel;
    if (day == today.subtract(const Duration(days: 1))) return l10n.yesterdayLabel;
    return DateFormat.MMMd(lang).format(local);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final String person;
    final String text;
    int? cents;
    VoidCallback? onTap;

    switch (activity.kind) {
      case ActivityKind.expense:
        final expense = expenses[activity.sourceId]!;
        person = expense.paidByName;
        text = '$person · ${expense.displayTitle(lang) ?? l10n.defaultExpenseTitle}';
        cents = expense.amountCents;
        onTap = () => context.push('/group/$groupId/expenses/${expense.id}');
      case ActivityKind.bought:
        final entry = entries[activity.sourceId]!;
        person = entry.boughtByName ?? '';
        text = l10n.activityBought(person, entry.name.localized(lang));
      case ActivityKind.settlement:
        final settlement = settlements[activity.sourceId]!;
        person = settlement.fromName;
        text = l10n.activitySettlement(settlement.fromName, settlement.toName);
        cents = settlement.cents;
    }

    return ListTile(
      leading: InitialAvatar(name: person),
      title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(_when(l10n, activity.at)),
      trailing: cents == null
          ? null
          : Text(formatCents(cents, locale: lang), style: moneyStyle(theme.textTheme.bodyLarge)),
      onTap: onTap,
    );
  }
}
