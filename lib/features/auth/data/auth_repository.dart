import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class AuthRepository {
  Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;

  Session? get currentSession => supabase.auth.currentSession;

  /// Only the display name goes into the auth metadata (the sign-up trigger copies it
  /// to `profiles`). The optional first/last name and phone are written to
  /// `profile_private` after sign-up instead: a copy in `auth.users` metadata would
  /// survive the user clearing them in the settings (withdrawing consent).
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supabase.auth.signOut();

  /// Deletes the account (`delete_my_account`, SPEC 16): leaves all groups, deletes the
  /// optional details and the login, keeps an anonymised profile ("Gelöschter Nutzer")
  /// so the groups' expenses and balances stay correct. Then clears the local session;
  /// the server-side sign-out can fail because the user no longer exists.
  Future<void> deleteMyAccount() async {
    await supabase.rpc('delete_my_account');
    try {
      await supabase.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Session already invalid: the local copy is removed either way.
    }
  }
}

/// Why a login or signup failed, from the error code Supabase Auth sends
/// (https://supabase.com/docs/guides/auth/debugging/error-codes).
enum AuthError {
  weakPassword,
  emailTaken,
  invalidCredentials,
  emailNotConfirmed,
  invalidEmail,
  tooManyAttempts,
  network,
  unknown,
}

AuthError authErrorFrom(Object error) {
  if (error is AuthRetryableFetchException) return AuthError.network;
  if (error is! AuthException) return AuthError.unknown;
  return switch (error.code) {
    'weak_password' => AuthError.weakPassword,
    'user_already_exists' || 'email_exists' => AuthError.emailTaken,
    'invalid_credentials' => AuthError.invalidCredentials,
    'email_not_confirmed' => AuthError.emailNotConfirmed,
    'email_address_invalid' || 'validation_failed' => AuthError.invalidEmail,
    'over_request_rate_limit' || 'over_email_send_rate_limit' => AuthError.tooManyAttempts,
    // Older Auth servers answer a wrong password without a code.
    _ when error.message == 'Invalid login credentials' => AuthError.invalidCredentials,
    _ => AuthError.unknown,
  };
}
