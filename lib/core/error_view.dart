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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    final scheme = Theme.of(context).colorScheme;
    final showAction = actionLabel != null && onAction != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center),
            if (showAction) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
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
