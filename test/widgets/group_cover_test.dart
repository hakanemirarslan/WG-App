import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/groups/ui/group_cover.dart';

import 'test_app.dart';

void main() {
  testWidgets('the tab header shows the group name and the line under it', (tester) async {
    await pumpTestApp(
      tester,
      const Scaffold(
        body: GroupTabHeader(title: 'Hako', subtitle: '3 üye'),
      ),
    );

    expect(find.text('Hako'), findsOneWidget);
    expect(find.text('3 üye'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the tab header shows a spinner while a photo uploads', (tester) async {
    await pumpTestApp(tester, const Scaffold(body: GroupTabHeader(title: 'Hako', busy: true)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('on a photo the header text is white, on the gradient it is not', (tester) async {
    Future<Color?> titleColour({required bool hasPhoto}) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: GroupBackdropScope(
            height: 400,
            hasPhoto: hasPhoto,
            child: const GroupTabHeader(title: 'Hako'),
          ),
        ),
      );
      return tester.widget<Text>(find.text('Hako')).style?.color;
    }

    expect(await titleColour(hasPhoto: true), Colors.white);
    expect(await titleColour(hasPhoto: false), isNot(Colors.white));
  });

  testWidgets('without a photo the backdrop is a gradient', (tester) async {
    await pumpTestApp(
      tester,
      const Scaffold(body: SizedBox(height: 300, child: GroupBackdrop(photoPath: null))),
    );

    expect(find.byType(Image), findsNothing);
  });
}
