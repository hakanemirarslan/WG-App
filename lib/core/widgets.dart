import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Rounded card with the spacing lists need (the theme's [Card] has no outer margin).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(color: color, child: child),
    );
  }
}

/// Small heading above a group of cards.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Brand mark shown above the login and signup forms.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.home_rounded, size: 40, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.appTitle, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

/// Colour for a signed balance: owed = positive tone, owing = error, settled = default text.
Color? balanceColor(BuildContext context, int cents) {
  if (cents > 0) return AppColors.of(context).positive;
  if (cents < 0) return Theme.of(context).colorScheme.error;
  return null;
}
