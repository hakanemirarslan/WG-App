import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale_provider.dart';
import '../../../core/error_view.dart';
import '../../../core/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/profile_repository.dart';
import '../providers/profile_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) =>
            ErrorView(error: error, onRetry: () => ref.invalidate(myProfileProvider)),
        data: (profile) => _SettingsForm(profile: profile),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, size: 18),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            label: Text(l10n.logoutButton),
          ),
        ),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late final TextEditingController _displayNameController;
  late String _selectedLocale;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.profile.displayName);
    _selectedLocale = widget.profile.locale;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(displayName: _displayNameController.text.trim(), locale: _selectedLocale);
      ref.read(appLocaleProvider.notifier).state = Locale(_selectedLocale);
      ref.invalidate(myProfileProvider);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.settingsSavedMessage)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile header: who is signed in, as on the person page of the balance tab.
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      InitialAvatar(name: widget.profile.displayName, radius: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.profile.displayName,
                          style: theme.textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _displayNameController,
                        decoration: InputDecoration(labelText: l10n.displayNameLabel),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLocale,
                        decoration: InputDecoration(labelText: l10n.languageLabel),
                        items: [
                          DropdownMenuItem(value: 'de', child: Text(l10n.germanLanguage)),
                          DropdownMenuItem(value: 'en', child: Text(l10n.englishLanguage)),
                          DropdownMenuItem(value: 'tr', child: Text(l10n.turkishLanguage)),
                        ],
                        onChanged: (value) => setState(() => _selectedLocale = value!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
