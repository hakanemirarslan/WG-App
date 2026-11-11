import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/images.dart';
import 'package:wg_app/core/widgets.dart';
import 'package:wg_app/features/settings/data/profile_repository.dart';
import 'package:wg_app/features/settings/providers/profile_providers.dart';
import 'package:wg_app/features/settings/ui/user_avatar.dart';

import 'test_app.dart';

void main() {
  const paths = {'u1': 'users/u1/avatar/11111111-1111-4111-8111-111111111111.jpg'};

  testWidgets('a person without a photo gets the first letter of their name', (tester) async {
    await pumpTestApp(
      tester,
      const Scaffold(
        body: UserAvatar(userId: 'u2', name: 'ayşe'),
      ),
      overrides: [avatarPathsProvider.overrideWith((ref) async => paths)],
    );
    await tester.pump();

    expect(find.byType(InitialAvatar), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a person with a photo gets the photo from the signed URL', (tester) async {
    await pumpTestApp(
      tester,
      const Scaffold(
        body: UserAvatar(userId: 'u1', name: 'ayşe'),
      ),
      overrides: [
        avatarPathsProvider.overrideWith((ref) async => paths),
        signedImageUrlProvider.overrideWith((ref, path) async => 'https://example.test/$path'),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ClipOval), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, endsWith(paths['u1']!));
  });

  testWidgets('photoPath overrides the shared lookup (own profile after a change)', (tester) async {
    await pumpTestApp(
      tester,
      const Scaffold(
        body: UserAvatar(userId: 'u1', name: 'ayşe', photoPath: 'users/u1/avatar/new.jpg'),
      ),
      overrides: [
        avatarPathsProvider.overrideWith((ref) async => paths),
        signedImageUrlProvider.overrideWith((ref, path) async => 'https://example.test/$path'),
      ],
    );
    await tester.pump();
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, endsWith('new.jpg'));
  });

  test('Profile reads avatar_path, null when there is none', () {
    expect(
      Profile.fromMap({'id': 'u1', 'display_name': 'A', 'locale': 'tr', 'avatar_path': 'x'})
          .avatarPath,
      'x',
    );
    expect(Profile.fromMap({'id': 'u1', 'display_name': 'A', 'locale': 'tr'}).avatarPath, isNull);
  });
}
