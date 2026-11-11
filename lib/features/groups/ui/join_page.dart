import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../data/groups_repository.dart';
import '../providers/groups_providers.dart';
import 'group_error_text.dart';

/// Opened via `/join/<code>` (SPEC 10). The router already sent logged-out users to
/// login first, so here we are signed in. Nobody joins just by opening a link: the
/// page shows which group it is and joins only after "Join group". (Before
/// 2026-11-12 it joined at once, so a crafted link could put someone into a
/// stranger's group without noticing.) Already a member: straight to the group.
class JoinPage extends ConsumerStatefulWidget {
  const JoinPage({super.key, required this.code});

  final String code;

  @override
  ConsumerState<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends ConsumerState<JoinPage> {
  InvitePreview? _preview;
  Object? _error;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await ref.read(groupsRepositoryProvider).previewInvite(widget.code);
      if (!mounted) return;
      if (preview.alreadyMember) {
        context.go('/group/${preview.groupId}');
        return;
      }
      setState(() => _preview = preview);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      final groupId = await ref.read(groupsRepositoryProvider).joinGroup(widget.code);
      ref.invalidate(myGroupsProvider);
      if (mounted) context.go('/group/$groupId');
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _joining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = _error;
    final preview = _preview;
    final Widget content;
    if (error != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(groupErrorText(l10n, error), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => context.go('/home'), child: Text(l10n.backToGroupsButton)),
        ],
      );
    } else if (preview == null) {
      content = const CircularProgressIndicator();
    } else {
      content = InviteConfirmView(
        preview: preview,
        joining: _joining,
        onJoin: _join,
        onCancel: () => context.go('/home'),
      );
    }
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(padding: const EdgeInsets.all(24), child: content),
        ),
      ),
    );
  }
}

/// "You are invited to `group`": name, member count, what joining means, and the two
/// choices. Separate from [JoinPage] so it can be tested without Supabase.
class InviteConfirmView extends StatelessWidget {
  const InviteConfirmView({
    super.key,
    required this.preview,
    required this.joining,
    required this.onJoin,
    required this.onCancel,
  });

  final InvitePreview preview;
  final bool joining;
  final VoidCallback onJoin;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.group_add_outlined, size: 32, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.inviteTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          preview.groupName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.memberCount(preview.memberCount),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.inviteHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: joining ? null : onJoin,
          child: joining
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.joinGroupConfirmButton),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: joining ? null : onCancel, child: Text(l10n.cancelButton)),
      ],
    );
  }
}
