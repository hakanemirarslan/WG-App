import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/groups/data/groups_repository.dart';
import 'package:wg_app/features/groups/ui/join_page.dart';

import 'test_app.dart';

void main() {
  final preview = InvitePreview(
    groupId: 'g1',
    groupName: 'Hako',
    memberCount: 3,
    alreadyMember: false,
  );

  testWidgets('shows which group the invite is for before joining', (tester) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: InviteConfirmView(preview: preview, joining: false, onJoin: () {}, onCancel: () {}),
      ),
    );
    final l10n = await l10nFor(const Locale('tr'));

    expect(find.text('Hako'), findsOneWidget);
    expect(find.text(l10n.memberCount(3)), findsOneWidget);
    expect(find.text(l10n.inviteHint), findsOneWidget);
  });

  testWidgets('joins only when the button is pressed, cancel does not join', (tester) async {
    var joined = 0;
    var cancelled = 0;
    await pumpTestApp(
      tester,
      Scaffold(
        body: InviteConfirmView(
          preview: preview,
          joining: false,
          onJoin: () => joined++,
          onCancel: () => cancelled++,
        ),
      ),
    );
    final l10n = await l10nFor(const Locale('tr'));

    expect(joined, 0); // showing the page alone joins nobody
    await tester.tap(find.text(l10n.cancelButton));
    expect((joined, cancelled), (0, 1));
    await tester.tap(find.text(l10n.joinGroupConfirmButton));
    expect(joined, 1);
  });

  testWidgets('both buttons are disabled while joining', (tester) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: InviteConfirmView(preview: preview, joining: true, onJoin: () {}, onCancel: () {}),
      ),
    );

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);
  });

  test('InvitePreview reads the RPC row', () {
    final parsed = InvitePreview.fromMap({
      'group_id': 'g1',
      'group_name': 'Hako',
      'photo_path': 'groups/g1/cover/x.jpg',
      'member_count': 3,
      'already_member': true,
    });
    expect(
      (parsed.groupId, parsed.groupName, parsed.memberCount, parsed.alreadyMember),
      ('g1', 'Hako', 3, true),
    );
    expect(parsed.photoPath, 'groups/g1/cover/x.jpg');
    // A group without a photo sends null.
    expect(
      InvitePreview.fromMap({
        'group_id': 'g1',
        'group_name': 'Hako',
        'photo_path': null,
        'member_count': 1,
        'already_member': false,
      }).photoPath,
      isNull,
    );
  });
}
