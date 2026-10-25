import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wg_app/features/auth/data/auth_repository.dart';

void main() {
  group('authErrorFrom', () {
    test('maps the Supabase Auth error codes', () {
      AuthError of(String code) => authErrorFrom(AuthApiException('x', code: code));
      expect(of('weak_password'), AuthError.weakPassword);
      expect(of('user_already_exists'), AuthError.emailTaken);
      expect(of('email_exists'), AuthError.emailTaken);
      expect(of('invalid_credentials'), AuthError.invalidCredentials);
      expect(of('email_not_confirmed'), AuthError.emailNotConfirmed);
      expect(of('email_address_invalid'), AuthError.invalidEmail);
      expect(of('over_request_rate_limit'), AuthError.tooManyAttempts);
      expect(of('over_email_send_rate_limit'), AuthError.tooManyAttempts);
    });

    test('the weak password exception is recognised by its code', () {
      final error = AuthWeakPasswordException(
        message: 'Password should be at least 8 characters.',
        statusCode: '422',
        reasons: ['length'],
      );
      expect(authErrorFrom(error), AuthError.weakPassword);
    });

    test('a wrong password without a code (older servers)', () {
      expect(
        authErrorFrom(const AuthApiException('Invalid login credentials')),
        AuthError.invalidCredentials,
      );
    });

    test('network failures and anything else', () {
      expect(authErrorFrom(AuthRetryableFetchException()), AuthError.network);
      expect(authErrorFrom(const AuthApiException('x', code: 'something_new')), AuthError.unknown);
      expect(authErrorFrom(Exception('boom')), AuthError.unknown);
    });
  });
}
