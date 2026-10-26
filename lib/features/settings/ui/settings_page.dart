import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale_provider.dart';
import '../../../core/error_view.dart';
import '../../../core/layout.dart';
import '../../../core/limits.dart';
import '../../../core/widgets.dart';
import '../../../domain/validation.dart';
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
      bottomNavigationBar: SafeArea(
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
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsSavedMessage)));
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

    // Accounts from before the signup fields existed may leave them empty; a value
    // that is already stored cannot be cleared again (signup made it required).
    FormFieldValidator<String> keepIfSet(String? stored) =>
        (value) =>
            (value ?? '').trim().isEmpty && stored != null ? l10n.requiredFieldMessage : null;

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
                        TextFormField(
                          controller: _displayNameController,
                          decoration: InputDecoration(labelText: l10n.displayNameLabel),
                          inputFormatters: limitTo(maxDisplayNameLength),
                          validator: (value) =>
                              (value ?? '').trim().isEmpty ? l10n.displayNameRequired : null,
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
                SectionHeader(l10n.privateInfoTitle),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
                          decoration: InputDecoration(labelText: l10n.firstNameLabel),
                          inputFormatters: limitTo(maxPersonNameLength),
                          textCapitalization: TextCapitalization.words,
                          validator: keepIfSet(widget.private.firstName),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(labelText: l10n.lastNameLabel),
                          inputFormatters: limitTo(maxPersonNameLength),
                          textCapitalization: TextCapitalization.words,
                          validator: keepIfSet(widget.private.lastName),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: l10n.phoneLabel,
                            hintText: l10n.phoneHint,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            final empty = (value ?? '').trim().isEmpty;
                            if (empty) return keepIfSet(widget.private.phone)(value);
                            return normalizePhone(value!) == null ? l10n.invalidPhoneMessage : null;
                          },
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
      ),
    );
  }
}
