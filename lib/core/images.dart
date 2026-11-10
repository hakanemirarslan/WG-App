import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/image_file.dart';
import 'supabase_client.dart';

/// Photos (SPEC 18): one private bucket, shown through short-lived signed URLs.
/// Who may read, upload or delete is decided by `image_access()` in the schema (RLS);
/// the app only builds the paths.
const _bucket = 'images';
const _signedUrlSeconds = 3600;

/// The picked file is neither JPEG, PNG nor WebP (detected from its content).
class UnsupportedImageException implements Exception {}

/// Still larger than the bucket limit after shrinking (e.g. a huge PNG).
class ImageTooLargeException implements Exception {}

class PickedImage {
  final Uint8List bytes;
  final String mimeType;

  const PickedImage(this.bytes, this.mimeType);
}

class ImageRepository {
  /// Opens the gallery (on phones the browser also offers the camera) and shrinks the
  /// image in the browser to [ImageKind.maxDimension]. Null = the user cancelled.
  Future<PickedImage?> pick(ImageKind kind) async {
    final size = kind.maxDimension.toDouble();
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: size,
      maxHeight: size,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final mimeType = detectImageMimeType(bytes);
    if (mimeType == null) throw UnsupportedImageException();
    if (bytes.length > maxImageBytes) throw ImageTooLargeException();
    return PickedImage(bytes, mimeType);
  }

  /// Uploads under a new random name and returns the Storage path to save in the row.
  /// Never overwrites: a replaced photo gets a new path, the old file is removed after.
  Future<String> upload(ImageKind kind, String ownerId, PickedImage image) async {
    final path = imagePath(
      kind: kind,
      ownerId: ownerId,
      fileId: newUuidV4(),
      mimeType: image.mimeType,
    );
    await supabase.storage
        .from(_bucket)
        .uploadBinary(path, image.bytes, fileOptions: FileOptions(contentType: image.mimeType));
    return path;
  }

  /// Deletes files that no row points to any more. Best effort: a failure only leaves an
  /// orphaned file behind (SPEC 18, known gap), so it must not stop what the user did.
  Future<void> remove(Iterable<String?> paths) async {
    final list = paths.whereType<String>().toList();
    if (list.isEmpty) return;
    try {
      await supabase.storage.from(_bucket).remove(list);
    } catch (e) {
      debugPrint('Image cleanup failed for $list: $e');
    }
  }

  Future<String> signedUrl(String path) =>
      supabase.storage.from(_bucket).createSignedUrl(path, _signedUrlSeconds);
}

final imageRepositoryProvider = Provider<ImageRepository>((ref) => ImageRepository());

/// Signed URL per path, reused while it is valid. Paths never change content (new name
/// on every upload), so the browser cache also works within that time.
final signedImageUrlProvider = FutureProvider.autoDispose.family<String, String>((ref, path) async {
  final link = ref.keepAlive();
  // Give the URL up a few minutes before it expires; the next build signs a new one.
  final timer = Timer(const Duration(seconds: _signedUrlSeconds - 300), link.close);
  ref.onDispose(timer.cancel);
  return ref.watch(imageRepositoryProvider).signedUrl(path);
});

/// Shows a photo from the `images` bucket; [fallback] while loading and on errors.
class StorageImage extends ConsumerWidget {
  const StorageImage({
    super.key,
    required this.path,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String path;
  final Widget fallback;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(signedImageUrlProvider(path));
    return url.when(
      data: (value) => Image.network(
        value,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => fallback,
      ),
      loading: () => fallback,
      error: (_, _) => fallback,
    );
  }
}
