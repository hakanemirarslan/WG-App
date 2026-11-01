import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/auth/ui/signup_page.dart';

import 'test_app.dart';

void main() {
  testWidgets('empty form: only display name, email and password are required', (tester) async {
    await pumpTestApp(tester, const SignupPage());
    final l10n = await l10nFor(const Locale('tr'));

    await tester.tap(find.widgetWithText(FilledButton, l10n.signupButton));
    await tester.pump();

    expect(find.text(l10n.requiredFieldMessage), findsOneWidget); // password
    expect(find.text(l10n.displayNameRequired), findsOneWidget);
    expect(find.text(l10n.errorInvalidEmail), findsOneWidget);
    // first name, last name and phone are optional (consent): no error when empty
    expect(find.text(l10n.invalidPhoneMessage), findsNothing);
  });

  testWidgets('name and phone fields are marked as optional', (tester) async {
    await pumpTestApp(tester, const SignupPage());
    final l10n = await l10nFor(const Locale('tr'));

    for (final label in [l10n.firstNameLabel, l10n.lastNameLabel, l10n.phoneLabel]) {
      expect(find.text('$label ${l10n.optionalSuffix}'), findsOneWidget);
    }
  });

  testWidgets('a malformed email and a phone without country code are rejected', (tester) async {
    await pumpTestApp(tester, const SignupPage());
    final l10n = await l10nFor(const Locale('tr'));

    await tester.enterText(find.widgetWithText(TextFormField, l10n.emailLabel), 'ana@example');
    await tester.enterText(
      find.widgetWithText(TextFormField, '${l10n.phoneLabel} ${l10n.optionalSuffix}'),
      '0151 2345678',
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.signupButton));
    await tester.pump();

    expect(find.text(l10n.errorInvalidEmail), findsOneWidget);
    expect(find.text(l10n.invalidPhoneMessage), findsOneWidget);
  });

  testWidgets('valid email and phone show no format errors', (tester) async {
    await pumpTestApp(tester, const SignupPage());
    final l10n = await l10nFor(const Locale('tr'));

    await tester.enterText(find.widgetWithText(TextFormField, l10n.emailLabel), 'ana@example.com');
    await tester.enterText(
      find.widgetWithText(TextFormField, '${l10n.phoneLabel} ${l10n.optionalSuffix}'),
      '+49 151 2345678',
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.signupButton));
    await tester.pump();

    expect(find.text(l10n.errorInvalidEmail), findsNothing);
    expect(find.text(l10n.invalidPhoneMessage), findsNothing);
  });

  testWidgets('the password rule is shown under the password field', (tester) async {
    await pumpTestApp(tester, const SignupPage());
    final l10n = await l10nFor(const Locale('tr'));

    expect(find.text(l10n.passwordRulesHint), findsOneWidget);
  });
}
