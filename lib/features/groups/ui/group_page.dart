import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../balances/providers/balances_providers.dart';
import '../data/groups_repository.dart';
import '../providers/groups_providers.dart';
import 'group_error_text.dart';

/// Group screen. For now only the "Group" tab content (members, invite,
/// leave); the shopping list / expenses / balance tabs come in later weeks.
class GroupPage extends ConsumerStatefulWidget {
  const GroupPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends ConsumerState<GroupPage> {
  String? _inviteLink;

  String _linkFor(String code) =>
      kIsWeb ? '${Uri.base.origin}/join/$code' : '/join/$code';

  void _showError(Object error) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(groupErrorText(l10n, error))));
  }

  Future<void> _createInvite() async {
    try {
      final code = await ref.read(groupsRepositoryProvider).createInvite(widget.groupId);
      if (mounted) setState(() => _inviteLink = _linkFor(code));
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _copyInvite() async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: _inviteLink!));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.linkCopiedMessage)));
  }

  Future<void> _setAdmin(Member member, bool admin) async {
    try {
      await ref
          .read(groupsRepositoryProvider)
          .setMemberRole(widget.groupId, member.userId, admin: admin);
      ref.invalidate(groupMembersProvider(widget.groupId));
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    // Leaving with an open balance is allowed (SPEC 10) but the user is warned.
    final myBalance = ref
        .read(balancesProvider(widget.groupId))
        .value
        ?.balances[supabase.auth.currentUser!.id];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveGroupConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.leaveGroupConfirmBody),
            if (myBalance != null && myBalance != 0) ...[
              const SizedBox(height: 12),
              Text(
                l10n.openBalanceWarning(formatCents(myBalance, locale: lang)),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.leaveGroupButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(groupsRepositoryProvider).leaveGroup(widget.groupId);
      ref.invalidate(myGroupsProvider);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    ref.watch(balancesProvider(widget.groupId)); // loaded for the leave warning
    final myId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text(groupAsync.value?.name ?? ''),
      ),
      body: membersAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(groupMembersProvider(widget.groupId)),
        ),
        data: (members) {
          final iAmAdmin = members.any((m) => m.userId == myId && m.isAdmin);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.membersTitle, style: Theme.of(context).textTheme.titleMedium),
              for (final member in members)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    member.userId == myId
                        ? '${member.displayName} ${l10n.youSuffix}'
                        : member.displayName,
                  ),
                  subtitle: member.isAdmin ? Text(l10n.adminRole) : null,
                  trailing: iAmAdmin && member.userId != myId
                      ? TextButton(
                          onPressed: () => _setAdmin(member, !member.isAdmin),
                          child: Text(
                            member.isAdmin ? l10n.removeAdminAction : l10n.makeAdminAction,
                          ),
                        )
                      : null,
                ),
              const Divider(height: 32),
              if (_inviteLink == null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.link),
                  onPressed: _createInvite,
                  label: Text(l10n.createInviteButton),
                )
              else ...[
                Text(l10n.inviteLinkReady, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                SelectableText(_inviteLink!),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyInvite,
                  label: Text(l10n.copyLinkButton),
                ),
              ],
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: _leave,
                label: Text(l10n.leaveGroupButton),
              ),
            ],
          );
        },
      ),
    );
  }
}
