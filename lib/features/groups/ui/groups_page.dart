import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets.dart';
import '../../../core/locale_provider.dart';
import '../../../core/error_view.dart';
import '../../../core/limits.dart';
import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/providers/balances_providers.dart';
import '../../settings/providers/profile_providers.dart';
import '../providers/groups_providers.dart';
import 'group_error_text.dart';

/// Group selection screen (SPEC 11, screen 2).
/// Also syncs the app-wide locale to `profiles.locale` on login (SPEC 12).
class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  Future<String?> _askText(BuildContext context, String label, String action, {int? maxLength}) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          inputFormatters: maxLength == null ? null : limitTo(maxLength),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancelButton)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _askText(
      context,
      l10n.groupNameLabel,
      l10n.createGroupButton,
      maxLength: maxGroupNameLength,
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      final id = await ref.read(groupsRepositoryProvider).createGroup(name);
      ref.invalidate(myGroupsProvider);
      if (context.mounted) context.go('/group/$id');
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _joinWithCode(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final code = await _askText(context, l10n.inviteCodeLabel, l10n.joinButton);
    if (code == null || code.isEmpty || !context.mounted) return;
    context.go('/join/$code');
  }

  void _showError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(groupErrorText(l10n, error))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(myProfileProvider, (previous, next) {
      next.whenData((profile) {
        ref.read(appLocaleProvider.notifier).state = Locale(profile.locale);
      });
    });
    final l10n = AppLocalizations.of(context)!;
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupsTitle),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) =>
            ErrorView(error: error, onRetry: () => ref.invalidate(myGroupsProvider)),
        data: (groups) => groups.isEmpty
            ? _Welcome(
                name: ref.watch(myProfileProvider).value?.displayName,
                onCreate: () => _create(context, ref),
                onJoin: () => _joinWithCode(context),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final (index, group) in groups.indexed)
                    FadeSlide(
                      delay: Duration(milliseconds: 60 + math.min(index, 8) * 60),
                      child: AnimatedPressCard(
                        onTap: () => context.go('/group/${group.id}'),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.home_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(group.name),
                          subtitle: _BalanceStatus(groupId: group.id),
                          trailing: _BalancePill(groupId: group.id),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      // Both actions side by side at the bottom, always reachable. Without a group the
      // welcome cards offer the same two actions, so the bar is hidden there.
      bottomNavigationBar: (groupsAsync.value?.isEmpty ?? true)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => _create(context, ref),
                        label: Text(l10n.createGroupButton),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.vpn_key_outlined, size: 18),
                        onPressed: () => _joinWithCode(context),
                        label: Text(l10n.joinWithCodeButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// First screen for someone without a group: the two ways in, explained (SPEC 11).
class _Welcome extends StatelessWidget {
  const _Welcome({required this.name, required this.onCreate, required this.onJoin});

  final String? name;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            if (name != null) Text(l10n.welcomeTitle(name!), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              l10n.welcomeBody,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FadeSlide(
              child: _WelcomeChoice(
                icon: Icons.add_home_outlined,
                title: l10n.createHomeTitle,
                body: l10n.createHomeBody,
                onTap: onCreate,
              ),
            ),
            FadeSlide(
              delay: const Duration(milliseconds: 80),
              child: _WelcomeChoice(
                icon: Icons.group_add_outlined,
                title: l10n.joinWithInviteTitle,
                body: l10n.joinWithInviteBody,
                onTap: onJoin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeChoice extends StatelessWidget {
  const _WelcomeChoice({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPressCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

/// My balance in [groupId], or null while it is loading or failed. Same numbers as the
/// Balance tab (`balancesProvider`); errors stay quiet here, the group itself shows them.
int? _myBalance(WidgetRef ref, String groupId) {
  final data = ref.watch(balancesProvider(groupId)).value;
  if (data == null) return null;
  return data.balances[supabase.auth.currentUser!.id] ?? 0;
}

/// "You are owed" / "You owe" / "All settled up" under the group name.
class _BalanceStatus extends ConsumerWidget {
  const _BalanceStatus({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cents = _myBalance(ref, groupId);
    if (cents == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Text(
      cents > 0
          ? l10n.youAreOwedStatus
          : cents < 0
          ? l10n.youOweStatus
          : l10n.allSettledUp,
    );
  }
}

/// Signed amount on a green (owed) or coral (owing) pill; a chevron when settled.
class _BalancePill extends ConsumerWidget {
  const _BalancePill({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cents = _myBalance(ref, groupId);
    if (cents == null || cents == 0) return const Icon(Icons.chevron_right);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return DecoratedBox(
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
    );
  }
}
