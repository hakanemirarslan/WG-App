import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'images.dart';

/// One button in the full-screen viewer's top bar (change, remove, ...).
class ImageViewerAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ImageViewerAction({required this.icon, required this.label, required this.onPressed});
}

/// Shows a stored photo full screen, zoomable (pinch, wheel, double-tap area), on a
/// black background. [actions] appear in the top bar; each closes the viewer first, so
/// the caller can continue (e.g. pick a new photo) on the page underneath.
Future<void> showImageViewer(
  BuildContext context, {
  required String path,
  String? title,
  List<ImageViewerAction> actions = const [],
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (context) => ImageViewer(path: path, title: title, actions: actions),
  );
}

class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key, required this.path, this.title, this.actions = const []});

  final String path;
  final String? title;
  final List<ImageViewerAction> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.closeButton,
            onPressed: () => Navigator.pop(context),
          ),
          title: title == null ? null : Text(title!),
          actions: [
            for (final action in actions)
              IconButton(
                icon: Icon(action.icon),
                tooltip: action.label,
                onPressed: () {
                  Navigator.pop(context);
                  action.onPressed();
                },
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: StorageImage(
              path: path,
              fit: BoxFit.contain,
              fallback: const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorFallback: const Center(
                child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.white54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded square preview of a stored photo; tapping it calls [onTap].
class PhotoThumbnail extends StatelessWidget {
  const PhotoThumbnail({super.key, required this.path, required this.onTap, this.size = 40});

  final String path;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_outlined, size: size * 0.5),
    );
    return Semantics(
      button: true,
      image: true,
      label: AppLocalizations.of(context)!.showPhotoAction,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: size,
            height: size,
            child: StorageImage(path: path, width: size, height: size, fallback: placeholder),
          ),
        ),
      ),
    );
  }
}
