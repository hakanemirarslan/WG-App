import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale_provider.dart';
import '../../../core/error_view.dart';
import '../../../core/layout.dart';
import '../../../core/limits.dart';
import '../../../core/theme_mode_provider.dart';
import '../../../core/widgets.dart';
import '../../../domain/validation.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../legal/ui/legal_page.dart';
import '../data/profile_repository.dart';
import '../providers/profile_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(myProfileProvider);
    final privateAsync = ref.watch(myPrivateProfileProvider);

    Widget body() {
      final error = profileAsync.error ?? privateAsync.error;
      if (error != null) {
        return ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(myProfileProvider);
            ref.invalidate(myPrivateProfileProvider);
          },
        );
      }
      final profile = profileAsync.value;
      final private = privateAsync.value;
      if (profile == null || private == null) return const LoadingView();
      return _SettingsForm(profile: profile, private: private);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: body(),
      bottomNavigationBar: isWideLayout(context)
          ? null
          : SafeArea(
              child: ContentWidth(
                maxWidth: 400,
                fitHeight: true,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    label: Text(l10n.logoutButton),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.profile, required this.private});

  final Profile profile;
  final PrivateProfile private;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late String _selectedLocale;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.profile.displayName);
    _firstNameController = TextEditingController(text: widget.private.firstName);
    _lastNameController = TextEditingController(text: widget.private.lastName);
    _phoneController = TextEditingController(text: widget.private.phone);
    _selectedLocale = widget.profile.locale;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Asks twice-careful confirmation, then deletes the account. Afterwards the router
  /// sends the (now signed-out) user to the login page.
  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAccountButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(authRepositoryProvider).deleteMyAccount();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(kDebugMode ? '${l10n.errorGeneric}\n$error' : l10n.errorGeneric)),
      );
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) return;
    String? orNull(String text) => text.trim().isEmpty ? null : text.trim();
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(
        displayName: _displayNameController.text.trim(),
        locale: _selectedLocale,
      );
      await repository.savePrivateProfile(
        PrivateProfile(
          firstName: orNull(_firstNameController.text),
          lastName: orNull(_lastNameController.text),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : normalizePhone(_phoneController.text),
        ),
      );
      ref.read(appLocaleProvider.notifier).state = Locale(_selectedLocale);
      ref.invalidate(myProfileProvider);
      ref.invalidate(myPrivateProfileProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsSavedMessage, textAlign: TextAlign.center)),
      );
    } catch (error) {
      messenger.showSnackBar(
        // Debug builds also show the raw error so unexpected failures are diagnosable.
        SnackBar(content: Text(kDebugMode ? '${l10n.errorGeneric}\n$error' : l10n.errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final header = AppCard(
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
    );
    final general = AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(labelText: l10n.displayNameLabel),
              inputFormatters: limitTo(maxDisplayNameLength),
              validator: (value) => (value ?? '').trim().isEmpty ? l10n.displayNameRequired : null,
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
            const SizedBox(height: 16),
            // Applies at once and is stored on this device (not with "Save").
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.themeLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {ref.watch(themeModeProvider)},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    ref.read(themeModeProvider.notifier).select(selection.first),
              ),
            ),
          ],
        ),
      ),
    );
    final private = AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.privateInfoHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstNameController,
              // Optional (consent): clearing a field and saving deletes the value.
              decoration: InputDecoration(
                labelText: '${l10n.firstNameLabel} ${l10n.optionalSuffix}',
              ),
              inputFormatters: limitTo(maxPersonNameLength),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: '${l10n.lastNameLabel} ${l10n.optionalSuffix}',
              ),
              inputFormatters: limitTo(maxPersonNameLength),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: '${l10n.phoneLabel} ${l10n.optionalSuffix}',
                hintText: l10n.phoneHint,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return null;
                return normalizePhone(value!) == null ? l10n.invalidPhoneMessage : null;
              },
            ),
          ],
        ),
      ),
    );
    final save = FilledButton(
      onPressed: _isSaving ? null : _save,
      child: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(l10n.saveButton),
    );
    final deleteAccount = TextButton.icon(
      icon: const Icon(Icons.delete_forever_outlined, size: 18),
      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
      onPressed: _deleteAccount,
      label: Text(l10n.deleteAccountButton),
    );

    // Wide windows (inside the group, next to the sidebar): profile across the top,
    // general settings and personal details side by side, actions bottom right.
    if (isWideLayout(context)) {
      return Form(
        key: _formKey,
        child: ContentWidth(
          maxWidth: 960,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [SectionHeader(l10n.generalSettingsTitle), general],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [SectionHeader(l10n.privateInfoTitle), private],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    deleteAccount,
                    const Spacer(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.logout, size: 18),
                      onPressed: () => ref.read(authRepositoryProvider).signOut(),
                      label: Text(l10n.logoutButton),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 160, child: save),
                  ],
                ),
                const SizedBox(height: 16),
                const LegalLinks(),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 8),
                general,
                SectionHeader(l10n.privateInfoTitle),
                private,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: save),
                const SizedBox(height: 8),
                deleteAccount,
                const LegalLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
