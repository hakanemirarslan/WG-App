import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/images.dart';
import '../../../l10n/app_localizations.dart';

/// Full-width background at the top of the "Group" tab (SPEC 18): the group photo,
/// darkened so the white text and buttons on it stay readable, fading into the page
/// colour at the bottom where the member cards continue. Without a photo, a gradient
/// in the theme colours that fades the same way.
class GroupBackdrop extends StatelessWidget {
  const GroupBackdrop({super.key, required this.photoPath});

  final String? photoPath;

  /// Height for a page [width] wide: grows with the width (40 %), so a wide window
  /// shows more of the photo, within 340..560 px.
  /// Whole pixels, so the photo and its overlay end on the same row.
  static double heightFor(double width) =>
      math.min(math.max(width * 0.4, 340), 560).roundToDouble();

  /// Text colour for anything drawn on the backdrop.
  static Color foregroundOn(BuildContext context, {required bool hasPhoto}) =>
      hasPhoto ? Colors.white : Theme.of(context).colorScheme.onPrimaryContainer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
      ),
    );
    final path = photoPath;

    final page = Theme.of(context).scaffoldBackgroundColor;
    final dark = path != null;

    // Photo (or gradient), then one fade on top: darker at the top for the back
    // button and the name, into the page colour at the bottom where the cards go on.
    // The photo is clipped to its box and the fade reaches 2 px below it: in debug
    // builds the photo's last pixel row otherwise showed as a thin light line.
    // (A ShaderMask fade-out was tried and does not apply to images on the web.)
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (path == null)
          gradient
        else
          // Fills the whole width (cover). A photo of another shape is cropped evenly
          // around its centre; the page makes the backdrop taller on wide windows
          // (heightFor), so less is cut off there.
          Semantics(
            label: l10n.groupPhotoTitle,
            image: true,
            child: ClipRect(
              child: StorageImage(path: path, fallback: gradient),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: -2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.4, 0.95, 1],
                colors: [
                  dark ? const Color(0x80000000) : Colors.transparent,
                  dark ? const Color(0x59000000) : Colors.transparent,
                  page,
                  page,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// What [GroupShell] tells the tabs about the backdrop behind them: its height (it
/// depends on the width) and whether it is a photo (white text) or the gradient.
class GroupBackdropScope extends InheritedWidget {
  const GroupBackdropScope({
    super.key,
    required this.height,
    required this.hasPhoto,
    required super.child,
  });

  final double height;
  final bool hasPhoto;

  static GroupBackdropScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GroupBackdropScope>();

  /// Text and icon colour on the backdrop.
  static Color foregroundOf(BuildContext context) =>
      GroupBackdrop.foregroundOn(context, hasPhoto: maybeOf(context)?.hasPhoto ?? false);

  @override
  bool updateShouldNotify(GroupBackdropScope oldWidget) =>
      height != oldWidget.height || hasPhoto != oldWidget.hasPhoto;
}

/// Transparent app bar of a group tab: the backdrop shows through, the back button
/// and [actions] in the backdrop's foreground colour. The group name is not in the bar
/// but on the photo ([GroupTabHeader]).
class GroupTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GroupTabAppBar({super.key, this.actions});

  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      foregroundColor: GroupBackdropScope.foregroundOf(context),
      leading: BackButton(onPressed: () => context.go('/home')),
      actions: [...?actions, const SizedBox(width: 8)],
    );
  }
}

/// First item in a group tab's scrolling content: the group name and a line about
/// this tab, on the photo. The cards that follow start on the photo and continue
/// below it.
class GroupTabHeader extends StatelessWidget {
  const GroupTabHeader({super.key, required this.title, this.subtitle, this.busy = false});

  final String title;
  final String? subtitle;

  /// A photo is being uploaded: a small spinner next to the name.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = GroupBackdropScope.foregroundOf(context);
    // Right below the app bar: a large gap pushed the content off the screen and made
    // every tab scroll. The photo still shows above and around the cards.
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (busy) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodyLarge?.copyWith(color: color.withValues(alpha: 0.85)),
            ),
          ],
        ],
      ),
    );
  }
}
