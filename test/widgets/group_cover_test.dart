import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/groups/data/groups_repository.dart';
import 'package:wg_app/features/groups/ui/group_cover.dart';

import 'test_app.dart';

void main() {
  final group = Group(id: 'g1', name: 'Hako');

  testWidgets('shows the name and member count on the cover without a photo', (tester) async {
    await pumpTestApp(
      tester,
      Scaffold(body: GroupCover(group: group, memberCount: 3, busy: false)),
    );
    final l10n = await l10nFor(const Locale('tr'));

    expect(find.text('Hako'), findsOneWidget);
    expect(find.text(l10n.memberCount(3)), findsOneWidget);
    // Not an admin: no buttons on the cover.
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('admins get the choose button, remove only when there is a photo', (tester) async {
    var changed = false;
    await pumpTestApp(
      tester,
      Scaffold(
        body: GroupCover(group: group, memberCount: 1, busy: false, onChange: () => changed = true),
      ),
    );
    final l10n = await l10nFor(const Locale('tr'));

    expect(find.byTooltip(l10n.choosePhotoButton), findsOneWidget);
    expect(find.byTooltip(l10n.removePhotoButton), findsNothing);
    await tester.tap(find.byTooltip(l10n.choosePhotoButton));
    expect(changed, isTrue);
  });

  testWidgets('buttons are disabled while a photo uploads', (tester) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: GroupCover(group: group, memberCount: 1, busy: true, onChange: () {}),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
  });
}
