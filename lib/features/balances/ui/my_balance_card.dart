import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../domain/pair_debts.dart';
import '../../../l10n/app_localizations.dart';

/// My balance in words instead of a signed number: "You are owed 4,00 €" with one
/// line per person ("Ana owes you 2,00 €"), or "You owe 2,00 €" ("You owe Hakan
/// 2,00 €"). A "+4" after paying 6 € for three people read as confusing; the lines
/// show where the number comes from. Shown on the overview (tappable) and the
/// Balance tab.
class MyBalanceCard extends StatelessWidget {
  const MyBalanceCard({
    super.key,
    required this.cents,
    required this.debts,
    required this.names,
    required this.lang,
    this.onTap,
  });

  /// My balance (SPEC 4): positive = I get money back.
  final int cents;

  /// My pairwise debts (`pairDebtsForUser`); they add up to -[cents].
  final List<PairDebt> debts;
  final Map<String, String> names;
  final String lang;
  final VoidCallback? onTap;

  static const _maxLines = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final settled = cents == 0;
    final title = cents > 0
        ? l10n.owedToYouTitle
        : cents < 0
        ? l10n.youOweTitle
        : l10n.allSettledUp;
    final amountColor = cents > 0 ? colors.positive : colors.negative;

    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (settled) ...[
                      Icon(Icons.check_circle_outline, color: colors.positive, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: settled
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                      ),
                    ),
                  ],
                ),
                if (!settled) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatCents(cents.abs(), locale: lang),
                    style: moneyStyle(theme.textTheme.headlineMedium?.copyWith(color: amountColor)),
                  ),
                ],
                if (debts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final debt in debts.take(_maxLines))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          InitialAvatar(name: names[debt.otherId] ?? '', radius: 12),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              debt.cents < 0
                                  ? l10n.owesYouLine(
                                      names[debt.otherId] ?? '',
                                      formatCents(-debt.cents, locale: lang),
                                    )
                                  : l10n.youOweLine(
                                      names[debt.otherId] ?? '',
                                      formatCents(debt.cents, locale: lang),
                                    ),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (debts.length > _maxLines)
                    Text(
                      '+${debts.length - _maxLines}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );

    return onTap == null
        ? AppCard(child: content)
        : AnimatedPressCard(onTap: onTap, child: content);
  }
}
