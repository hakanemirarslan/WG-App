import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/debt_simplifier.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/providers/groups_providers.dart';
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
        content: Text(l10n.markPaidConfirmBody(
          data.names[transfer.from] ?? '',
          data.names[transfer.to] ?? '',
          formatCents(transfer.cents, locale: lang),
        )),
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
      await ref.read(settlementsRepositoryProvider).recordSettlement(
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.errorGeneric),
              if (kDebugMode) SelectableText('$error'),
            ],
          ),
        ),
        data: (data) {
          final visible = data.visibleUserIds;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!data.consistent)
                Card(
                  color: scheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.balancesMismatchMessage,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ),
              Text(l10n.balancesTitle, style: Theme.of(context).textTheme.titleMedium),
              for (final id in visible)
                _BalanceTile(
                  name: data.names[id] ?? '',
                  isFormer: !data.activeMemberIds.contains(id),
                  cents: data.balances[id]!,
                  lang: lang,
                ),
              const Divider(height: 32),
              Text(
                l10n.suggestedPaymentsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (data.transfers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(l10n.allSettledUp),
                ),
              for (final transfer in data.transfers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.transferLine(
                    data.names[transfer.from] ?? '',
                    data.names[transfer.to] ?? '',
                  )),
                  subtitle: Text(formatCents(transfer.cents, locale: lang)),
                  // Only the payer or the receiver may record the payment (SPEC 9).
                  trailing: transfer.from == myId || transfer.to == myId
                      ? OutlinedButton(
                          onPressed: () => _markPaid(context, ref, data, transfer),
                          child: Text(l10n.markPaidButton),
                        )
                      : null,
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
    final scheme = Theme.of(context).colorScheme;
    final color = cents > 0
        ? Colors.green.shade700
        : cents < 0
            ? scheme.error
            : null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(isFormer ? '$name ${l10n.formerMemberSuffix}' : name),
      subtitle: cents == 0 ? null : Text(cents > 0 ? l10n.isOwedLabel : l10n.owesLabel),
      trailing: Text(
        // Signed, so owed (+) and owing (-) are distinguishable without colour.
        '${cents > 0 ? '+' : ''}${formatCents(cents, locale: lang)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
    );
  }
}
