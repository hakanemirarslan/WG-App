import 'package:flutter/material.dart';

import '../../../core/images.dart';
import '../../../l10n/app_localizations.dart';
import '../data/groups_repository.dart';

/// Header of the "Group" tab (SPEC 18): the group photo fills a wide, rounded cover with
/// the name on a dark fade at the bottom. Without a photo, a gradient in the theme
/// colours. Admins get two buttons on the cover: choose/change and remove.
class GroupCover extends StatelessWidget {
  const GroupCover({
    super.key,
    required this.group,
    required this.memberCount,
    required this.busy,
    this.onChange,
    this.onRemove,
  });

  final Group group;
  final int memberCount;
  final bool busy;

  /// Null hides the button (not an admin).
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

  static const _height = 200.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasPhoto = group.photoPath != null;

    final noPhoto = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.75, -0.3),
        child: Icon(
          Icons.home_rounded,
          size: 120,
          color: scheme.onPrimaryContainer.withValues(alpha: 0.12),
        ),
      ),
    );
    // On a photo the text needs a dark fade behind it; on the gradient the theme's
    // own text colour is readable as it is.
    final textColor = hasPhoto ? Colors.white : scheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: _height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                Semantics(
                  label: l10n.groupPhotoTitle,
                  image: true,
                  child: StorageImage(
                    path: group.photoPath!,
                    width: double.infinity,
                    height: _height,
                    fallback: noPhoto,
                  ),
                )
              else
                noPhoto,
              if (hasPhoto)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 1],
                      colors: [Colors.transparent, Color(0xB3000000)],
                    ),
                  ),
                ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.memberCount(memberCount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (onChange != null || onRemove != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (onChange != null)
                        _CoverButton(
                          icon: Icons.photo_camera_outlined,
                          tooltip: hasPhoto ? l10n.changePhotoButton : l10n.choosePhotoButton,
                          onPressed: busy ? null : onChange,
                        ),
                      if (onRemove != null) ...[
                        const SizedBox(width: 8),
                        _CoverButton(
                          icon: Icons.delete_outline,
                          tooltip: l10n.removePhotoButton,
                          onPressed: busy ? null : onRemove,
                        ),
                      ],
                    ],
                  ),
                ),
              if (busy)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round, half-transparent dark button that stays visible on any photo.
class _CoverButton extends StatelessWidget {
  const _CoverButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x73000000),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0x40000000),
        disabledForegroundColor: Colors.white54,
      ),
    );
  }
}
