import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/widgets.dart';

import 'test_app.dart';

void main() {
  testWidgets('the eye button shows and hides the password', (tester) async {
    final controller = TextEditingController(text: 'Geheim123');
    addTearDown(controller.dispose);
    await pumpTestApp(
      tester,
      Scaffold(
        body: PasswordField(controller: controller, autofillHints: const []),
      ),
    );

    bool obscured() => tester.widget<EditableText>(find.byType(EditableText)).obscureText;

    expect(obscured(), isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(obscured(), isTrue);
  });
}
