import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets.dart';
import '../../../core/limits.dart';
import '../../../core/locale_provider.dart';
import '../../../core/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/providers/profile_providers.dart';
import '../providers/auth_providers.dart';
import 'auth_error_text.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
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
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
          );
      // The signup trigger only sets display_name; apply the chosen locale too.
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(displayName: _displayNameController.text.trim(), locale: _selectedLocale);
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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AuthHeader(),
                    TextField(
                      controller: _displayNameController,
                      decoration: InputDecoration(labelText: l10n.displayNameLabel),
                      inputFormatters: limitTo(maxDisplayNameLength),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.nickname],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: l10n.emailLabel),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: l10n.passwordLabel),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
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
    );
  }
}
