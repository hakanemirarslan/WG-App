import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which motif a screen gets behind its content.
enum BackgroundStyle {
  /// Login, signup, join: soft blobs, ring, dot grid and a wave.
  welcome,

  /// Group list: houses.
  home,

  /// Shopping list: checkboxes.
  shopping,

  /// Expenses (list, detail, form): coins and a receipt edge.
  expenses,

  /// Balances: two overlapping circles on a balance beam.
  balance,

  /// Monthly summary: bars with a trend line.
  summary,

  /// Group members: people.
  group,

  /// Settings: gears.
  settings,
}

/// Per-screen backdrop. Wrapped around a route's page in the router; the page's
/// scaffold is transparent so the shapes show through between the cards.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.style, required this.child});

  final BackgroundStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _BackgroundPainter(
              style: style,
              base: scheme.surface,
              tint: scheme.surfaceContainer,
              primary: scheme.primary,
              secondary: scheme.secondary,
              tertiary: scheme.tertiary,
              dark: scheme.brightness == Brightness.dark,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter({
    required this.style,
    required this.base,
    required this.tint,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.dark,
  });

  final BackgroundStyle style;
  final Color base;
  final Color tint;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Shapes scale with the short side but stay sane on wide desktop windows.
    final unit = math.min(math.min(w, h), 520.0);
    final boost = dark ? 0.75 : 1.0;

    // Three-stop gradient for a richer background.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.55, 1.0],
          colors: [base, tint, Color.lerp(tint, primary, 0.06)!],
        ).createShader(Offset.zero & size),
    );

    Color c(Color color, double alpha) => color.withValues(alpha: alpha * boost);
    Paint fill(Color color, double alpha) => Paint()..color = c(color, alpha);
    Paint stroke(Color color, double alpha, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = c(color, alpha);

    void blob(Offset center, double radius, Color color, double alpha, int seed) =>
        canvas.drawPath(_blobPath(center, radius, seed), fill(color, alpha));

    switch (style) {
      case BackgroundStyle.welcome:
        blob(Offset(w * 0.98, h * 0.04), unit * 0.62, primary, 0.22, 1);
        blob(Offset(w * 0.0, h * 0.42), unit * 0.42, secondary, 0.26, 2);
        blob(Offset(w * 0.9, h * 0.92), unit * 0.55, tertiary, 0.2, 3);
        blob(Offset(w * 0.08, h * 1.0), unit * 0.3, primary, 0.14, 4);
        canvas.drawCircle(Offset(w * 0.14, h * 0.09), unit * 0.1, stroke(primary, 0.38, 3));
        _dotGrid(canvas, Offset(w - unit * 0.34, h * 0.5), unit * 0.045, fill(secondary, 0.5));
        _wave(canvas, w, h * 0.8, unit, stroke(tertiary, 0.28, 3));
        _wave(canvas, w, h * 0.82, unit, stroke(primary, 0.12, 2));

      case BackgroundStyle.home:
        blob(Offset(w * 0.95, h * 0.1), unit * 0.5, primary, 0.18, 5);
        blob(Offset(w * 0.0, h * 0.75), unit * 0.45, secondary, 0.22, 6);
        blob(Offset(w * 0.5, h * 0.5), unit * 0.3, tertiary, 0.1, 17);
        _house(canvas, Offset(w * 0.78, h * 0.78), unit * 0.34, stroke(primary, 0.38, 3));
        _house(canvas, Offset(w * 0.12, h * 0.2), unit * 0.18, stroke(tertiary, 0.38, 3));
        _house(canvas, Offset(w * 0.5, h * 0.93), unit * 0.14, stroke(secondary, 0.44, 3));
        _dotGrid(canvas, Offset(w * 0.06, h * 0.5), unit * 0.045, fill(secondary, 0.45));

      case BackgroundStyle.shopping:
        blob(Offset(w * 1.0, h * 0.18), unit * 0.5, tertiary, 0.14, 7);
        blob(Offset(w * 0.0, h * 0.85), unit * 0.5, primary, 0.14, 8);
        final box = unit * 0.1;
        _checkbox(canvas, Offset(w * 0.1, h * 0.14), box, true, stroke(primary, 0.32, 3));
        _checkbox(canvas, Offset(w * 0.84, h * 0.44), box * 1.3, false, stroke(secondary, 0.38, 3));
        _checkbox(canvas, Offset(w * 0.06, h * 0.56), box * 0.8, false, stroke(tertiary, 0.34, 3));
        _checkbox(canvas, Offset(w * 0.78, h * 0.86), box, true, stroke(primary, 0.3, 3));
        canvas.drawCircle(Offset(w * 0.9, h * 0.1), unit * 0.02, fill(secondary, 0.4));
        canvas.drawCircle(Offset(w * 0.3, h * 0.94), unit * 0.025, fill(tertiary, 0.4));

      case BackgroundStyle.expenses:
        blob(Offset(w * 0.0, h * 0.1), unit * 0.45, secondary, 0.16, 9);
        blob(Offset(w * 1.0, h * 0.7), unit * 0.55, primary, 0.14, 10);
        _coin(canvas, Offset(w * 0.86, h * 0.14), unit * 0.14, stroke(tertiary, 0.34, 3));
        _coin(canvas, Offset(w * 0.1, h * 0.6), unit * 0.1, stroke(primary, 0.32, 3));
        _coin(canvas, Offset(w * 0.3, h * 0.92), unit * 0.18, stroke(secondary, 0.3, 3));
        // Torn receipt edge down the right side.
        final edge = Path()..moveTo(w - 6, h * 0.3);
        for (var y = h * 0.3, i = 0; y < h * 0.62; y += unit * 0.03, i++) {
          edge.lineTo(w - (i.isEven ? 6 : 6 + unit * 0.025), y);
        }
        canvas.drawPath(edge, stroke(primary, 0.3, 2.5));

      case BackgroundStyle.balance:
        final cy = h * 0.82;
        canvas.drawCircle(Offset(w * 0.34, cy), unit * 0.3, fill(primary, 0.16));
        canvas.drawCircle(Offset(w * 0.66, cy), unit * 0.3, fill(tertiary, 0.16));
        // Beam with a fulcrum.
        final beamY = h * 0.18;
        canvas.drawLine(
          Offset(w * 0.12, beamY),
          Offset(w * 0.88, beamY),
          stroke(secondary, 0.4, 4),
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.5, beamY + 4)
            ..lineTo(w * 0.5 - unit * 0.06, beamY + unit * 0.12)
            ..lineTo(w * 0.5 + unit * 0.06, beamY + unit * 0.12)
            ..close(),
          fill(secondary, 0.3),
        );
        canvas.drawCircle(
          Offset(w * 0.12, beamY + unit * 0.08),
          unit * 0.05,
          stroke(primary, 0.4, 3),
        );
        canvas.drawCircle(
          Offset(w * 0.88, beamY + unit * 0.08),
          unit * 0.05,
          stroke(tertiary, 0.4, 3),
        );
        blob(Offset(w * 1.0, h * 0.45), unit * 0.4, secondary, 0.12, 11);

      case BackgroundStyle.summary:
        blob(Offset(w * 0.05, h * 0.08), unit * 0.45, tertiary, 0.14, 12);
        final bars = [0.35, 0.55, 0.42, 0.75, 0.62, 0.9];
        final barW = unit * 0.08;
        final gap = unit * 0.045;
        final startX = w - (barW + gap) * bars.length - unit * 0.04;
        final points = <Offset>[];
        for (var i = 0; i < bars.length; i++) {
          final bh = bars[i] * unit * 0.5;
          final x = startX + i * (barW + gap);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, h - bh, barW, bh + 12),
              Radius.circular(barW / 2),
            ),
            fill(i.isEven ? primary : secondary, 0.2),
          );
          points.add(Offset(x + barW / 2, h - bh - unit * 0.08));
        }
        final trend = Path()..moveTo(points.first.dx, points.first.dy);
        for (final p in points.skip(1)) {
          trend.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(trend, stroke(tertiary, 0.4, 3));
        for (final p in points) {
          canvas.drawCircle(p, 4, fill(tertiary, 0.5));
        }
        canvas.drawCircle(Offset(w * 0.12, h * 0.55), unit * 0.07, stroke(primary, 0.28, 3));

      case BackgroundStyle.group:
        blob(Offset(w * 0.95, h * 0.9), unit * 0.5, secondary, 0.16, 13);
        blob(Offset(w * 0.0, h * 0.3), unit * 0.4, primary, 0.14, 14);
        _person(canvas, Offset(w * 0.82, h * 0.16), unit * 0.1, stroke(primary, 0.34, 3));
        _person(canvas, Offset(w * 0.92, h * 0.24), unit * 0.07, stroke(tertiary, 0.34, 3));
        _person(canvas, Offset(w * 0.12, h * 0.78), unit * 0.12, stroke(secondary, 0.38, 3));
        _person(canvas, Offset(w * 0.28, h * 0.86), unit * 0.08, stroke(primary, 0.32, 3));
        _dotGrid(canvas, Offset(w * 0.06, h * 0.12), unit * 0.045, fill(tertiary, 0.35));

      case BackgroundStyle.settings:
        blob(Offset(w * 0.0, h * 0.05), unit * 0.4, secondary, 0.14, 15);
        blob(Offset(w * 1.0, h * 0.95), unit * 0.5, primary, 0.14, 16);
        _gear(canvas, Offset(w * 0.86, h * 0.2), unit * 0.16, stroke(primary, 0.34, 3));
        _gear(canvas, Offset(w * 0.12, h * 0.7), unit * 0.1, stroke(tertiary, 0.36, 3));
        _gear(canvas, Offset(w * 0.7, h * 0.9), unit * 0.07, stroke(secondary, 0.4, 3));
    }
  }

  void _dotGrid(Canvas canvas, Offset origin, double step, Paint paint) {
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 5; col++) {
        canvas.drawCircle(origin + Offset(col * step, row * step), 2, paint);
      }
    }
  }

  void _wave(Canvas canvas, double w, double y, double unit, Paint paint) {
    final wave = Path()..moveTo(0, y);
    for (var x = 0.0; x <= w; x += 4) {
      wave.lineTo(x, y + math.sin(x / unit * 2 * math.pi * 1.4) * unit * 0.03);
    }
    canvas.drawPath(wave, paint);
  }

  /// Outline of a house: walls plus a pitched roof. [size] is the wall width.
  void _house(Canvas canvas, Offset center, double size, Paint paint) {
    final half = size / 2;
    final top = center.dy - half * 0.2;
    final path = Path()
      ..moveTo(center.dx - half, top)
      ..lineTo(center.dx, center.dy - half * 1.1)
      ..lineTo(center.dx + half, top)
      ..moveTo(center.dx - half * 0.8, top)
      ..lineTo(center.dx - half * 0.8, center.dy + half * 0.8)
      ..lineTo(center.dx + half * 0.8, center.dy + half * 0.8)
      ..lineTo(center.dx + half * 0.8, top)
      ..moveTo(center.dx - half * 0.2, center.dy + half * 0.8)
      ..lineTo(center.dx - half * 0.2, center.dy + half * 0.3)
      ..lineTo(center.dx + half * 0.2, center.dy + half * 0.3)
      ..lineTo(center.dx + half * 0.2, center.dy + half * 0.8);
    canvas.drawPath(path, paint);
  }

  void _checkbox(Canvas canvas, Offset center, double size, bool checked, Paint paint) {
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(size * 0.25)), paint);
    if (checked) {
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - size * 0.25, center.dy)
          ..lineTo(center.dx - size * 0.05, center.dy + size * 0.2)
          ..lineTo(center.dx + size * 0.28, center.dy - size * 0.22),
        paint,
      );
    }
  }

  void _coin(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.7, paint);
  }

  /// Head and shoulders glyph. [radius] is the head radius.
  void _person(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
    final shoulders = Rect.fromCenter(
      center: center + Offset(0, radius * 2.6),
      width: radius * 3.4,
      height: radius * 2.6,
    );
    canvas.drawArc(shoulders, math.pi, math.pi, false, paint);
  }

  void _gear(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius * 0.75, paint);
    canvas.drawCircle(center, radius * 0.3, paint);
    const teeth = 8;
    for (var i = 0; i < teeth; i++) {
      final angle = 2 * math.pi * i / teeth;
      canvas.drawLine(
        center + Offset.fromDirection(angle, radius * 0.75),
        center + Offset.fromDirection(angle, radius),
        paint,
      );
    }
  }

  /// Smooth closed shape: points on a circle with wobbling radius, joined by
  /// quadratic curves through the midpoints so there are no corners.
  Path _blobPath(Offset center, double radius, int seed) {
    const n = 8;
    final points = <Offset>[
      for (var i = 0; i < n; i++)
        center + Offset.fromDirection(2 * math.pi * i / n, radius * (0.72 + 0.5 * _noise(seed, i))),
    ];
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

    final path = Path();
    final start = mid(points[n - 1], points[0]);
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final control = points[i];
      final end = mid(points[i], points[(i + 1) % n]);
      path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    }
    return path..close();
  }

  /// Deterministic pseudo-random value in [0, 1) so the shapes never change between frames.
  double _noise(int seed, int i) {
    final v = math.sin(seed * 12.9898 + i * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.style != style ||
      old.base != base ||
      old.tint != tint ||
      old.primary != primary ||
      old.secondary != secondary ||
      old.tertiary != tertiary ||
      old.dark != dark;
}
