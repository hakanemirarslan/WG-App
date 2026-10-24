import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shared error state for screens: generic message, optional retry button.
/// The raw error is only shown in debug builds.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: scheme.error),
            const SizedBox(height: 12),
            Text(l10n.errorGeneric, textAlign: TextAlign.center),
            if (kDebugMode && error != null) SelectableText('$error'),
            if (onRetry != null) TextButton(onPressed: onRetry, child: Text(l10n.retryButton)),
          ],
        ),
      ),
    );
  }
}

/// Centered spinner used as the loading state on all screens.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

/// Shared empty state: a soft icon badge, the message and an optional action
/// (both [actionLabel] and [onAction] are needed for the button to show).
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showAction = actionLabel != null && onAction != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (showAction) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                onPressed: onAction,
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
