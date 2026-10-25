import 'package:flutter/foundation.dart' show kDebugMode;

import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

/// User-facing text for a failed login or signup, in the app language.
String authErrorText(AppLocalizations l10n, Object error) {
  final text = switch (authErrorFrom(error)) {
    AuthError.weakPassword => l10n.errorWeakPassword,
    AuthError.emailTaken => l10n.errorEmailTaken,
    AuthError.invalidCredentials => l10n.errorInvalidCredentials,
    AuthError.emailNotConfirmed => l10n.errorEmailNotConfirmed,
    AuthError.invalidEmail => l10n.errorInvalidEmail,
    AuthError.tooManyAttempts => l10n.errorTooManyAttempts,
    AuthError.network => l10n.errorNetwork,
    AuthError.unknown => l10n.errorGeneric,
  };
  // Debug builds also show the raw error so unexpected failures are diagnosable.
  return kDebugMode ? '$text\n$error' : text;
}
