import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets.dart';
import '../../../core/money.dart';
import '../../../domain/balance.dart';
import '../../../domain/monthly_summary.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../groups/providers/groups_providers.dart';
import '../providers/balances_providers.dart';

/// Monthly summary (SPEC 9): expenses of one month, what each person paid and
/// owes, and the balance at the end of that month.
class MonthlySummaryPage extends ConsumerStatefulWidget {
  const MonthlySummaryPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<MonthlySummaryPage> createState() => _MonthlySummaryPageState();
}

class _MonthlySummaryPageState extends ConsumerState<MonthlySummaryPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final balanceAsync = ref.watch(balancesProvider(widget.groupId));
    final expenses = ref.watch(expensesProvider(widget.groupId)).value;
    final settlements = ref.watch(settlementsProvider(widget.groupId)).value;

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    Widget body() {
      final data = balanceAsync.value;
      if (balanceAsync.hasError) {
        return ErrorView(
          error: balanceAsync.error,
          onRetry: () {
            ref.invalidate(expensesProvider(widget.groupId));
            ref.invalidate(settlementsProvider(widget.groupId));
            ref.invalidate(groupMembersProvider(widget.groupId));
          },
        );
      }
      if (data == null || expenses == null || settlements == null) {
        return const LoadingView();
      }

      final summary = summarizeMonth(
        year: _month.year,
        month: _month.month,
        expenses: balanceExpensesOf(expenses),
        settlements: [
          for (final s in settlements)
            BalanceSettlement(from: s.from, to: s.to, cents: s.cents, createdAt: s.createdAt),
        ],
        memberIds: data.activeMemberIds,
      );

      // Active members, plus anyone with activity or an open balance that month.
      final userIds = {
        ...data.activeMemberIds,
        ...summary.paidByUser.keys,
        ...summary.shareByUser.keys,
        ...summary.endBalances.entries.where((e) => e.value != 0).map((e) => e.key),
      }.toList()..sort((a, b) => (data.names[a] ?? '').compareTo(data.names[b] ?? ''));

      // All bars share one scale so people can be compared at a glance.
      final maxCents = userIds
          .expand((id) => [summary.paidByUser[id] ?? 0, summary.shareByUser[id] ?? 0])
          .fold(0, (a, b) => a > b ? a : b);

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(l10n.monthlyTotalLabel, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    formatCents(summary.totalCents, locale: lang),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.expenseCount(summary.expenseCount)),
                ],
              ),
            ),
          ),
          if (summary.expenseCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.noExpensesThisMonth, textAlign: TextAlign.center),
            ),
          const SizedBox(height: 8),
          for (final id in userIds)
            _PersonSummary(
              name: data.names[id] ?? '',
              isFormer: !data.activeMemberIds.contains(id),
              paid: summary.paidByUser[id] ?? 0,
              share: summary.shareByUser[id] ?? 0,
              maxCents: maxCents,
              endBalance: summary.endBalances[id] ?? 0,
              lang: lang,
            ),
        ],
      );
    }

    // Do not go before the first expense; there is nothing to show there.
    final firstExpense = (expenses == null || expenses.isEmpty)
        ? null
        : expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestMonth = firstExpense == null
        ? currentMonth
        : DateTime(firstExpense.year, firstExpense.month);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.previousMonthTooltip,
              icon: const Icon(Icons.chevron_left),
              onPressed: _month.isAfter(earliestMonth) ? () => _shift(-1) : null,
            ),
            Text(DateFormat.yMMMM(lang).format(_month)),
            IconButton(
              tooltip: l10n.nextMonthTooltip,
              icon: const Icon(Icons.chevron_right),
              onPressed: _month.isBefore(currentMonth) ? () => _shift(1) : null,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: body(),
    );
  }
}

class _PersonSummary extends StatelessWidget {
  const _PersonSummary({
    required this.name,
    required this.isFormer,
    required this.paid,
    required this.share,
    required this.maxCents,
    required this.endBalance,
    required this.lang,
  });

  final String name;
  final bool isFormer;
  final int paid;
  final int share;
  final int maxCents;
  final int endBalance;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final endColor = onBalanceContainerColor(context, endBalance);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFormer ? '$name ${l10n.formerMemberSuffix}' : name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _Line(l10n.paidLabel, formatCents(paid, locale: lang)),
            _Bar(cents: paid, maxCents: maxCents, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            _Line(l10n.shareLabel, formatCents(share, locale: lang)),
            _Bar(cents: share, maxCents: maxCents, color: Theme.of(context).colorScheme.tertiary),
            const SizedBox(height: 6),
            // The end balance sits on a green/red pill so owed and owing stand out.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: balanceContainerColor(context, endBalance),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _Line(
                l10n.endBalanceLabel,
                '${endBalance > 0 ? '+' : ''}${formatCents(endBalance, locale: lang)}',
                color: endColor,
                bold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin horizontal bar; the length is only a visual hint (display, not money maths).
class _Bar extends StatelessWidget {
  const _Bar({required this.cents, required this.maxCents, required this.color});

  final int cents;
  final int maxCents;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: maxCents == 0 ? 0 : cents / maxCents,
        minHeight: 8,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.color, this.bold = false});

  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: color, fontWeight: bold ? FontWeight.bold : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}
