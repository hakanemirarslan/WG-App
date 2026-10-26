import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/auth/ui/signup_page.dart';

import 'test_app.dart';

void main() {
  testWidgets('empty signup form: every field is reported as required', (tester) async {
    await pumpTestApp(tester, const SignupPage());
    final l10n = await l10nFor(const Locale('tr'));

    await tester.tap(find.widgetWithText(FilledButton, l10n.signupButton));
    await tester.pump();

    // first name, last name, phone, password
    expect(find.text(l10n.requiredFieldMessage), findsNWidgets(4));
    expect(find.text(l10n.displayNameRequired), findsOneWidget);
    expect(find.text(l10n.errorInvalidEmail), findsOneWidget);
  });

  testWidgets('a malformed email and a phone without country code are rejected', (tester) async {
    await pumpTestApp(tester, const SignupPage());
    final l10n = await l10nFor(const Locale('tr'));

    await tester.enterText(find.widgetWithText(TextFormField, l10n.emailLabel), 'ana@example');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.phoneLabel), '0151 2345678');
    await tester.tap(find.widgetWithText(FilledButton, l10n.signupButton));
    await tester.pump();

    expect(find.text(l10n.errorInvalidEmail), findsOneWidget);
    expect(find.text(l10n.invalidPhoneMessage), findsOneWidget);
  });

  testWidgets('valid email and phone show no format errors', (tester) async {
    await pumpTestApp(tester, const SignupPage());
    final l10n = await l10nFor(const Locale('tr'));

    await tester.enterText(find.widgetWithText(TextFormField, l10n.emailLabel), 'ana@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.phoneLabel), '+49 151 2345678');
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
