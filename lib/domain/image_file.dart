import 'dart:math';

/// Where a photo belongs (SPEC 18). Each kind has its own Storage folder and the size the
/// browser shrinks it to before uploading (the free Supabase plan cannot resize).
enum ImageKind {
  groupCover('groups', 'cover', 1024),
  avatar('users', 'avatar', 512),
  shoppingItem('groups', 'items', 1024),
  receipt('groups', 'receipts', 2000);

  const ImageKind(this.root, this.folder, this.maxDimension);

  /// `groups` (owner = group id) or `users` (owner = user id).
  final String root;
  final String folder;

  /// Longest side in pixels after shrinking.
  final int maxDimension;
}

/// Same limit as the `images` bucket (`file_size_limit`).
const maxImageBytes = 2 * 1024 * 1024;

/// The image types the bucket accepts, keyed by MIME type, with the file extension.
const _extensions = {'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp'};

/// Detects JPEG, PNG or WebP from the first bytes ("magic numbers"). The file name or the
/// browser's MIME type cannot be trusted, so the content decides. Null = not accepted.
String? detectImageMimeType(List<int> bytes) {
  bool startsWith(List<int> prefix, [int offset = 0]) {
    if (bytes.length < offset + prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[offset + i] != prefix[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return 'image/png';
  // RIFF....WEBP
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) && startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  return null;
}

/// File extension for an accepted MIME type (`jpg`, `png`, `webp`).
String imageExtension(String mimeType) {
  final extension = _extensions[mimeType];
  if (extension == null) throw ArgumentError.value(mimeType, 'mimeType', 'not an accepted image');
  return extension;
}

/// Random version 4 UUID in lower case, the form the Storage policies expect.
String newUuidV4([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Storage path: `<root>/<ownerId>/<folder>/<fileId>.<extension>`, the only form
/// `image_access()` and the check constraints in the schema accept.
String imagePath({
  required ImageKind kind,
  required String ownerId,
  required String fileId,
  required String mimeType,
}) => '${kind.root}/$ownerId/${kind.folder}/$fileId.${imageExtension(mimeType)}';
