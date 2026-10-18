import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/groups_providers.dart';
import 'group_error_text.dart';

/// Opened via `/join/<code>`. The router already sent logged-out users to
/// login first, so here we are signed in and can call `join_group` directly.
class JoinPage extends ConsumerStatefulWidget {
  const JoinPage({super.key, required this.code});

  final String code;

  @override
  ConsumerState<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends ConsumerState<JoinPage> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    try {
      final groupId = await ref.read(groupsRepositoryProvider).joinGroup(widget.code);
      ref.invalidate(myGroupsProvider);
      if (mounted) context.go('/group/$groupId');
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = _error;
    return Scaffold(
      body: Center(
        child: error == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.joiningGroupMessage),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(groupErrorText(l10n, error), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/home'),
                      child: Text(l10n.backToGroupsButton),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
