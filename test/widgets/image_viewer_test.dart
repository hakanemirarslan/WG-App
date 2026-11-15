import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/image_viewer.dart';
import 'package:wg_app/core/images.dart';
import 'package:wg_app/features/shopping_list/data/shopping_repository.dart';

import 'test_app.dart';

void main() {
  final signedUrl = signedImageUrlProvider.overrideWith(
    (ref, path) async => 'https://example.test/$path',
  );

  testWidgets('the viewer shows the photo and closes with the X', (tester) async {
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showImageViewer(context, path: 'groups/g/items/p.jpg', title: 'Süt'),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [signedUrl],
    );
    final l10n = await l10nFor(const Locale('tr'));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Süt'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect((tester.widget<Image>(find.byType(Image)).image as NetworkImage).url, endsWith('p.jpg'));

    await tester.tap(find.byTooltip(l10n.closeButton));
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewer), findsNothing);
  });

  testWidgets('an action closes the viewer first, then runs', (tester) async {
    var removed = 0;
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showImageViewer(
              context,
              path: 'groups/g/items/p.jpg',
              actions: [
                ImageViewerAction(
                  icon: Icons.delete_outline,
                  label: 'remove',
                  onPressed: () => removed++,
                ),
              ],
            ),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [signedUrl],
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('remove'));
    await tester.pumpAndSettle();

    expect(removed, 1);
    expect(find.byType(ImageViewer), findsNothing);
  });

  testWidgets('without actions the viewer offers only closing', (tester) async {
    await pumpTestApp(
      tester,
      const ImageViewer(path: 'groups/g/items/p.jpg'),
      overrides: [signedUrl],
    );

    // Only the close button: nobody without the right gets change/remove.
    expect(find.byType(IconButton), findsOneWidget);
  });

  test('ShoppingEntry reads photo_path', () {
    Map<String, dynamic> row(String? photo) => {
      'id': 'e1',
      'group_item_id': 'i1',
      'note': null,
      'added_by': 'u1',
      'status': 'open',
      'bought_by': null,
      'bought_at': null,
      'created_at': '2026-11-15T10:00:00Z',
      'expense_id': null,
      'photo_path': photo,
      'group_items': null,
      'adder': {'display_name': 'A'},
      'buyer': null,
    };
    expect(ShoppingEntry.fromMap(row('groups/g/items/p.jpg')).photoPath, 'groups/g/items/p.jpg');
    expect(ShoppingEntry.fromMap(row(null)).photoPath, isNull);
  });
}
