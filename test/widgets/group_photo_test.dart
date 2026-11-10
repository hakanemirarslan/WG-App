import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/groups/ui/group_photo.dart';

import 'test_app.dart';

void main() {
  testWidgets('a group without a photo shows the house icon', (tester) async {
    await pumpTestApp(tester, const Scaffold(body: GroupPhoto(photoPath: null, radius: 30)));

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.radius, 30);
  });
}
