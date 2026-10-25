import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class AuthRepository {
  Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;

  Session? get currentSession => supabase.auth.currentSession;

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
