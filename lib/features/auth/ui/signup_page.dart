import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets.dart';
import '../../../core/limits.dart';
import '../../../core/locale_provider.dart';
import '../../../core/router.dart';
import '../../../domain/validation.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/providers/profile_providers.dart';
import '../providers/auth_providers.dart';
import 'auth_error_text.dart';

/// Signup (SPEC 11). Every field is required: first and last name and phone are only
/// visible to the user (`profile_private`), the display name is what the group sees.
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  late String _selectedLocale;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedLocale = deviceLocaleOrDefault().languageCode;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Checked before signUp: once the account exists, a bad value could only be
    // fixed in the settings.
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final displayName = _displayNameController.text.trim();
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: displayName,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: normalizePhone(_phoneController.text)!,
          );
      // The signup trigger only sets display_name; apply the chosen locale too.
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(displayName: displayName, locale: _selectedLocale);
      ref.read(appLocaleProvider.notifier).state = Locale(_selectedLocale);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = authErrorText(AppLocalizations.of(context)!, e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String? required(String? value) =>
        (value ?? '').trim().isEmpty ? l10n.requiredFieldMessage : null;

    Widget nameField(TextEditingController controller, String label, String autofill) =>
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          inputFormatters: limitTo(maxPersonNameLength),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: [autofill],
          validator: required,
        );

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AuthHeader(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: nameField(
                              _firstNameController,
                              l10n.firstNameLabel,
                              AutofillHints.givenName,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: nameField(
                              _lastNameController,
                              l10n.lastNameLabel,
                              AutofillHints.familyName,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: InputDecoration(labelText: l10n.displayNameLabel),
                        inputFormatters: limitTo(maxDisplayNameLength),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.nickname],
                        validator: (value) =>
                            (value ?? '').trim().isEmpty ? l10n.displayNameRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: l10n.emailLabel),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) =>
                            isValidEmail(value ?? '') ? null : l10n.errorInvalidEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: l10n.phoneLabel,
                          hintText: l10n.phoneHint,
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) return l10n.requiredFieldMessage;
                          return normalizePhone(value!) == null ? l10n.invalidPhoneMessage : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      PasswordField(
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.newPassword],
                        // Same rule as in the Supabase Auth settings (SPEC 13); the server
                        // checks it, the hint tells the user up front.
                        helperText: l10n.passwordRulesHint,
                        validator: (value) =>
                            (value ?? '').isEmpty ? l10n.requiredFieldMessage : null,
                        onSubmitted: (_) {
                          if (!_isSubmitting) _submit();
                        },
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
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.signupButton),
                      ),
                      TextButton(
                        onPressed: () => context.go(
                          authPath('/login', GoRouterState.of(context).uri.queryParameters['from']),
                        ),
                        child: Text(l10n.haveAccountSwitchToLogin),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
