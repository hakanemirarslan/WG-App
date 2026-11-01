import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/auth/ui/login_page.dart';
import 'package:wg_app/features/legal/ui/legal_page.dart';

import 'test_app.dart';

void main() {
  testWidgets('the privacy policy page shows the text from assets/legal', (tester) async {
    await pumpTestApp(tester, const LegalPage(document: LegalDocument.privacy));
    await tester.pumpAndSettle();
    final l10n = await l10nFor(const Locale('tr'));

    expect(find.text(l10n.privacyPolicyTitle), findsOneWidget); // app bar
    expect(find.textContaining('Datenschutzerklärung'), findsWidgets);
    // the list is lazy: check a heading near the top, not text further down
    expect(find.textContaining('Verantwortlicher'), findsWidgets);
  });

  testWidgets('the imprint page loads', (tester) async {
    await pumpTestApp(tester, const LegalPage(document: LegalDocument.imprint));
    await tester.pumpAndSettle();
    final l10n = await l10nFor(const Locale('tr'));

    expect(find.text(l10n.imprintTitle), findsOneWidget);
    expect(find.textContaining('Impressum'), findsWidgets);
  });

  testWidgets('the login form links to both legal pages', (tester) async {
    await pumpTestApp(tester, const LoginPage());
    final l10n = await l10nFor(const Locale('tr'));

    expect(find.widgetWithText(TextButton, l10n.privacyPolicyTitle), findsOneWidget);
    expect(find.widgetWithText(TextButton, l10n.imprintTitle), findsOneWidget);
  });
}
