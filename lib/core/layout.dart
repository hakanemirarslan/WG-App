import 'package:flutter/widgets.dart';

/// Window width from which the app switches to the desktop layout: a navigation rail
/// on the left instead of the bottom tab bar, and two columns on the overview.
/// 840 px is Material 3's "expanded" breakpoint.
const wideLayoutBreakpoint = 840.0;

/// Readable width for lists and forms; wider windows centre the content.
const contentMaxWidth = 600.0;

/// Width of the two-column overview on wide windows.
const wideContentMaxWidth = 1100.0;

bool isWideLayout(BuildContext context) => MediaQuery.sizeOf(context).width >= wideLayoutBreakpoint;

/// Centres [child] and keeps it at most [maxWidth] wide (the page itself stays full
/// width, so its background and app bar reach the window edges).
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = contentMaxWidth,
    this.fitHeight = false,
  });

  final Widget child;
  final double maxWidth;

  /// True for bottom bars: only as tall as [child] (a plain Center would take all
  /// the height a `bottomNavigationBar` slot offers).
  final bool fitHeight;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: fitHeight ? 1 : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
