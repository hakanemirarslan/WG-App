import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/image_file.dart';

void main() {
  group('detectImageMimeType', () {
    test('recognises JPEG, PNG and WebP by their first bytes', () {
      expect(detectImageMimeType([0xFF, 0xD8, 0xFF, 0xE0, 0, 0]), 'image/jpeg');
      expect(
        detectImageMimeType([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0]),
        'image/png',
      );
      expect(
        detectImageMimeType([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50, 0]),
        'image/webp',
      );
    });

    test('rejects other formats, RIFF that is not WebP, and too short input', () {
      expect(detectImageMimeType('GIF89a'.codeUnits), isNull);
      expect(detectImageMimeType('%PDF-1.7'.codeUnits), isNull);
      // RIFF....WAVE (audio)
      expect(
        detectImageMimeType([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x41, 0x56, 0x45]),
        isNull,
      );
      expect(detectImageMimeType([0xFF, 0xD8]), isNull);
      expect(detectImageMimeType([]), isNull);
    });
  });

  group('imageExtension', () {
    test('maps the accepted types and throws for others', () {
      expect(imageExtension('image/jpeg'), 'jpg');
      expect(imageExtension('image/png'), 'png');
      expect(imageExtension('image/webp'), 'webp');
      expect(() => imageExtension('image/gif'), throwsArgumentError);
    });
  });

  group('newUuidV4', () {
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('has the lower-case version 4 form the Storage policies expect', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(newUuidV4(Random(seed)), matches(uuidPattern));
      }
      expect(newUuidV4(), matches(uuidPattern));
    });

    test('differs between calls', () {
      expect(newUuidV4(), isNot(newUuidV4()));
    });
  });

  group('imagePath', () {
    const id = '0b6f4a1e-1c2d-4e3f-8a9b-0c1d2e3f4a5b';
    const file = '11111111-1111-4111-8111-111111111111';

    test('builds the folder per kind', () {
      expect(
        imagePath(kind: ImageKind.groupCover, ownerId: id, fileId: file, mimeType: 'image/jpeg'),
        'groups/$id/cover/$file.jpg',
      );
      expect(
        imagePath(kind: ImageKind.avatar, ownerId: id, fileId: file, mimeType: 'image/webp'),
        'users/$id/avatar/$file.webp',
      );
      expect(
        imagePath(kind: ImageKind.shoppingItem, ownerId: id, fileId: file, mimeType: 'image/png'),
        'groups/$id/items/$file.png',
      );
      expect(
        imagePath(kind: ImageKind.receipt, ownerId: id, fileId: file, mimeType: 'image/jpeg'),
        'groups/$id/receipts/$file.jpg',
      );
    });

    test('matches the pattern of the schema check constraints', () {
      // Same regex as groups_photo_path_check in supabase/schema.sql.
      final schemaPattern = RegExp('^groups/$id/cover/[0-9a-f-]{36}\\.(jpg|png|webp)\$');
      final path = imagePath(
        kind: ImageKind.groupCover,
        ownerId: id,
        fileId: newUuidV4(),
        mimeType: 'image/jpeg',
      );
      expect(path, matches(schemaPattern));
    });

    test('receipts keep the most detail, avatars the least', () {
      expect(ImageKind.receipt.maxDimension, greaterThan(ImageKind.groupCover.maxDimension));
      expect(ImageKind.avatar.maxDimension, lessThan(ImageKind.shoppingItem.maxDimension));
    });
  });
}
