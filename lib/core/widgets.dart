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
    this.duration = const Duration(milliseconds: 300),
    this.offset = const Offset(0, 12),
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

/// Small heading above a group of cards (also used for the day headers).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Password input with an eye button to show or hide what was typed
/// (used on the login and signup forms).
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.autofillHints,
    this.helperText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final List<String> autofillHints;
  final String? helperText;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: widget.controller,
      obscureText: !_visible,
      textInputAction: TextInputAction.done,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: l10n.passwordLabel,
        helperText: widget.helperText,
        helperMaxLines: 2,
        suffixIcon: IconButton(
          icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          tooltip: _visible ? l10n.hidePasswordTooltip : l10n.showPasswordTooltip,
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

/// Round avatar with the first letter of a person's name.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.name, this.radius = 18});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.home_rounded, size: 26, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.appTitle, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

/// [base] with digits of equal width, so amounts in a column line up (Inter supports it).
TextStyle? moneyStyle(TextStyle? base) =>
    base?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

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
