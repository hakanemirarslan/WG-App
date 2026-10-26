import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout.dart';
import '../../../core/widgets.dart';
import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
import '../../../core/theme.dart';
import '../../../domain/debt_simplifier.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/providers/groups_providers.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../groups/ui/group_error_text.dart';
import '../providers/balances_providers.dart';
import 'my_balance_card.dart';

/// "Balance" tab (SPEC 9, 11): my balance, member balances and suggested payments.
class BalancePage extends ConsumerWidget {
  const BalancePage({super.key, required this.groupId});

  final String groupId;

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    BalanceData data,
    Transfer transfer,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.markPaidConfirmTitle),
        content: Text(
          l10n.markPaidConfirmBody(
            data.names[transfer.from] ?? '',
            data.names[transfer.to] ?? '',
            formatCents(transfer.cents, locale: lang),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.markPaidButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(settlementsRepositoryProvider)
          .recordSettlement(
            groupId: groupId,
            from: transfer.from,
            to: transfer.to,
            cents: transfer.cents,
          );
      ref.invalidate(settlementsProvider(groupId));
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
    final groupName = ref.watch(groupProvider(groupId)).value?.name ?? '';
    final balanceAsync = ref.watch(balancesProvider(groupId));
    final expenses = ref.watch(expensesProvider(groupId)).value;
    final settlements = ref.watch(settlementsProvider(groupId)).value;
    final myId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text(groupName),
      ),
      body: ContentWidth(
        child: balanceAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(expensesProvider(groupId));
              ref.invalidate(settlementsProvider(groupId));
              ref.invalidate(groupMembersProvider(groupId));
            },
          ),
          data: (data) {
            final visible = data.visibleUserIds;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!data.consistent) _MismatchNotice(message: l10n.balancesMismatchMessage),
                MyBalanceCard(
                  cents: data.balances[myId] ?? 0,
                  debts: expenses == null || settlements == null
                      ? const []
                      : pairDebtsForUser(myId, expenses, settlements),
                  names: data.names,
                  lang: lang,
                ),
                SectionHeader(l10n.balancesTitle),
                AppCard(
                  child: Column(
                    children: [
                      for (final (index, id) in visible.indexed) ...[
                        if (index > 0) const Divider(indent: 16, endIndent: 16),
                        _MemberRow(
                          name: data.names[id] ?? '',
                          isFormer: !data.activeMemberIds.contains(id),
                          cents: data.balances[id]!,
                          lang: lang,
                          onTap: () => context.push('/group/$groupId/balance/person/$id'),
                        ),
                      ],
                    ],
                  ),
                ),
                SectionHeader(l10n.suggestedPaymentsTitle),
                if (data.transfers.isEmpty)
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
                  )
                else
                  AppCard(
                    child: Column(
                      children: [
                        for (final (index, transfer) in data.transfers.indexed) ...[
                          if (index > 0) const Divider(indent: 16, endIndent: 16),
                          _TransferRow(
                            text: l10n.transferLine(
                              data.names[transfer.from] ?? '',
                              data.names[transfer.to] ?? '',
                            ),
                            cents: transfer.cents,
                            lang: lang,
                            // Only the payer or the receiver may record the payment (SPEC 9).
                            onMarkPaid: transfer.from == myId || transfer.to == myId
                                ? () => _markPaid(context, ref, data, transfer)
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                AnimatedPressCard(
                  onTap: () => context.push('/group/$groupId/balance/summary'),
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_month_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(l10n.monthlySummaryButton),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Warning when the balances do not add up to zero (should never happen).
class _MismatchNotice extends StatelessWidget {
  const _MismatchNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One member: initial avatar, name, "is owed / owes" in words and the amount on a
/// green or coral pill. No +/- sign: the word says the direction (a signed number
/// read as confusing).
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.isFormer,
    required this.cents,
    required this.lang,
    required this.onTap,
  });

  final String name;
  final bool isFormer;
  final int cents;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          initial,
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
        ),
      ),
      title: Text(isFormer ? '$name ${l10n.formerMemberSuffix}' : name),
      subtitle: cents == 0 ? null : Text(cents > 0 ? l10n.isOwedLabel : l10n.owesLabel),
      trailing: DecoratedBox(
        decoration: BoxDecoration(
          color: balanceContainerColor(context, cents),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            formatCents(cents.abs(), locale: lang),
            style: moneyStyle(
              theme.textTheme.titleSmall?.copyWith(color: onBalanceContainerColor(context, cents)),
            ),
          ),
        ),
      ),
    );
  }
}

/// One suggested payment ("A pays B", amount) with a compact "mark as paid" button
/// for the two people involved.
class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.text,
    required this.cents,
    required this.lang,
    required this.onMarkPaid,
  });

  final String text;
  final int cents;
  final String lang;
  final VoidCallback? onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  formatCents(cents, locale: lang),
                  style: moneyStyle(
                    theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          if (onMarkPaid != null) ...[
            const SizedBox(width: 12),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: onMarkPaid,
              child: Text(l10n.markPaidButton),
            ),
          ],
        ],
      ),
    );
  }
}
