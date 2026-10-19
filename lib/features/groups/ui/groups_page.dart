import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale_provider.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/providers/profile_providers.dart';
import '../providers/groups_providers.dart';
import 'group_error_text.dart';

/// Group selection screen (SPEC 11, screen 2).
/// Also syncs the app-wide locale to `profiles.locale` on login (SPEC 12).
class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  Future<String?> _askText(BuildContext context, String label, String action) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
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
    final name = await _askText(context, l10n.groupNameLabel, l10n.createGroupButton);
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(myGroupsProvider),
        ),
        data: (groups) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(l10n.noGroupsYet, textAlign: TextAlign.center),
              ),
            for (final group in groups)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(group.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/group/${group.id}'),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () => _create(context, ref),
              label: Text(l10n.createGroupButton),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.vpn_key_outlined),
              onPressed: () => _joinWithCode(context),
              label: Text(l10n.joinWithCodeButton),
            ),
          ],
        ),
      ),
    );
  }
}
