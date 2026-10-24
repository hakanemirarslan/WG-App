import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Micro-animations
// ─────────────────────────────────────────────────────────────────────────────

/// Fades in and slides up from a small offset. Wrap around any widget that
/// should animate in. Use [delay] to stagger multiple items.
class FadeSlide extends StatefulWidget {
  const FadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 24),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(offset: _slide.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// A card that scales down slightly on press — gives a tactile press feel.
class AnimatedPressCard extends StatefulWidget {
  const AnimatedPressCard({super.key, required this.child, this.onTap, this.color});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  State<AnimatedPressCard> createState() => _AnimatedPressCardState();
}

class _AnimatedPressCardState extends State<AnimatedPressCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // InkWell (not a bare GestureDetector) gives the card a ripple, keyboard focus,
    // a pointer cursor on web and tap semantics for screen readers.
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
      child: AppCard(
        color: widget.color,
        child: Semantics(
          button: widget.onTap != null,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (pressed) => pressed ? _ctrl.forward() : _ctrl.reverse(),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Rounded card with a subtle border (shape comes from the card theme).
/// Use [AppCard] for static cards; [AnimatedPressCard] for tappable ones.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(color: color, child: child),
    );
  }
}

/// Small heading above a group of cards.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand mark shown above the login and signup forms.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          // Gradient avatar ring
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.tertiary],
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.home_rounded, size: 44, color: scheme.onPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.appTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              foreground: Paint()
                ..shader = LinearGradient(colors: [scheme.primary, scheme.tertiary])
                    .createShader(const Rect.fromLTWH(0, 0, 200, 50)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Background for a signed balance: owed = green container, owing = coral container,
/// settled = null (callers keep their default surface).
Color? balanceContainerColor(BuildContext context, int cents) {
  final colors = AppColors.of(context);
  if (cents > 0) return colors.positiveContainer;
  if (cents < 0) return colors.negativeContainer;
  return null;
}

/// Text colour that stays readable on [balanceContainerColor].
Color? onBalanceContainerColor(BuildContext context, int cents) {
  final colors = AppColors.of(context);
  if (cents > 0) return colors.onPositiveContainer;
  if (cents < 0) return colors.onNegativeContainer;
  return null;
}
