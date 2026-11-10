import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/images.dart';

/// Records deletions instead of calling Supabase Storage.
class _RecordingImages extends ImageRepository {
  final removed = <String>[];
  final log = <String>[];

  @override
  Future<void> remove(Iterable<String?> paths) async {
    for (final path in paths.whereType<String>()) {
      removed.add(path);
      log.add('remove $path');
    }
  }
}

void main() {
  group('ImageRepository.replace', () {
    test('saves the new path first, then deletes the old file', () async {
      final images = _RecordingImages();
      await images.replace(
        oldPath: 'old.jpg',
        newPath: 'new.jpg',
        save: (path) async => images.log.add('save $path'),
      );
      expect(images.log, ['save new.jpg', 'remove old.jpg']);
    });

    test('removing a photo saves null and deletes the old file', () async {
      final images = _RecordingImages();
      String? saved = 'unchanged';
      await images.replace(oldPath: 'old.jpg', newPath: null, save: (path) async => saved = path);
      expect(saved, isNull);
      expect(images.removed, ['old.jpg']);
    });

    test('a first photo deletes nothing', () async {
      final images = _RecordingImages();
      await images.replace(oldPath: null, newPath: 'new.jpg', save: (_) async {});
      expect(images.removed, isEmpty);
    });

    test('if saving fails, the new upload is deleted and the old file kept', () async {
      final images = _RecordingImages();
      await expectLater(
        images.replace(
          oldPath: 'old.jpg',
          newPath: 'new.jpg',
          save: (_) async => throw StateError('not_admin'),
        ),
        throwsStateError,
      );
      expect(images.removed, ['new.jpg']);
    });
  });
}
