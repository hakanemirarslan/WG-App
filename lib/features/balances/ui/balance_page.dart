import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets.dart';
import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/debt_simplifier.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/providers/groups_providers.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../groups/ui/group_error_text.dart';
import '../providers/balances_providers.dart';

/// "Balance" tab (SPEC 9, 11): member balances and suggested payments.
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
    final myId = supabase.auth.currentUser!.id;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text(groupName),
      ),
      body: balanceAsync.when(
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
              if (!data.consistent)
                AppCard(
                  color: scheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.balancesMismatchMessage,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ),
              AppCard(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        l10n.yourBalanceLabel,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _signed(data.balances[myId] ?? 0, lang),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
              SectionHeader(l10n.balancesTitle),
              for (final id in visible)
                _BalanceTile(
                  name: data.names[id] ?? '',
                  isFormer: !data.activeMemberIds.contains(id),
                  cents: data.balances[id]!,
                  lang: lang,
                ),
              SectionHeader(l10n.suggestedPaymentsTitle),
              if (data.transfers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(l10n.allSettledUp),
                ),
              for (final transfer in data.transfers)
                AppCard(
                  child: ListTile(
                    title: Text(
                      l10n.transferLine(
                        data.names[transfer.from] ?? '',
                        data.names[transfer.to] ?? '',
                      ),
                    ),
                    subtitle: Text(formatCents(transfer.cents, locale: lang)),
                    // Only the payer or the receiver may record the payment (SPEC 9).
                    trailing: transfer.from == myId || transfer.to == myId
                        ? OutlinedButton(
                            onPressed: () => _markPaid(context, ref, data, transfer),
                            child: Text(l10n.markPaidButton),
                          )
                        : null,
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => context.push('/group/$groupId/balance/summary'),
                label: Text(l10n.monthlySummaryButton),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.name,
    required this.isFormer,
    required this.cents,
    required this.lang,
  });

  final String name;
  final bool isFormer;
  final int cents;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = balanceColor(context, cents);

    return AppCard(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(isFormer ? '$name ${l10n.formerMemberSuffix}' : name),
        subtitle: cents == 0 ? null : Text(cents > 0 ? l10n.isOwedLabel : l10n.owesLabel),
        trailing: Text(
          // Signed, so owed (+) and owing (-) are distinguishable without colour.
          _signed(cents, lang),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}

String _signed(int cents, String lang) =>
    '${cents > 0 ? '+' : ''}${formatCents(cents, locale: lang)}';
