import 'dart:math' as math;
import 'dart:ui';

import '../../core/theme/app_colors.dart';

/// Drawing primitives for BLADNA's illustration style: flat color, a warm
/// ink outline and simple geometric shapes. Every painter in the app uses
/// these helpers so the artwork stays consistent.
class Kit {
  static Paint fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  static Paint ink([double width = 1.4, Color color = AppColors.ink]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  static double clamp01(double v) => v < 0 ? 0.0 : (v > 1 ? 1.0 : v);

  /// Linear ramp: 0 below [from], 1 above [to].
  static double ramp(double v, double from, double to) =>
      to <= from ? (v >= to ? 1.0 : 0.0) : clamp01((v - from) / (to - from));

  static void outlined(Canvas c, Path p, Color color, {double stroke = 1.4}) {
    c.drawPath(p, fill(color));
    if (stroke > 0) c.drawPath(p, ink(stroke));
  }

  static void rrect(Canvas c, Rect r, double radius, Color color, {double stroke = 1.4}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, fill(color));
    if (stroke > 0) c.drawRRect(rr, ink(stroke));
  }

  static void circle(Canvas c, Offset o, double r, Color color, {double stroke = 1.4}) {
    c.drawCircle(o, r, fill(color));
    if (stroke > 0) c.drawCircle(o, r, ink(stroke));
  }

  /// Draws [path] as a dashed line.
  static void dashed(Canvas c, Path path, Paint paint, {double dash = 6, double gap = 5}) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = math.min(d + dash, metric.length);
        c.drawPath(metric.extractPath(d, end), paint);
        d = end + gap;
      }
    }
  }

  /// Diagonal hatch used for locked zones.
  static void hatch(Canvas c, Rect r, Color color, {double spacing = 10}) {
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)));
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (var x = r.left - r.height; x < r.right; x += spacing) {
      c.drawLine(Offset(x, r.bottom), Offset(x + r.height, r.top), p);
    }
    c.restore();
  }

  /// Deterministic pseudo-random points inside [r] (same every frame).
  static List<Offset> scatter(Rect r, int count, int seed, {double margin = 6}) {
    final rng = math.Random(seed);
    return List.generate(count, (_) {
      return Offset(
        r.left + margin + rng.nextDouble() * (r.width - 2 * margin),
        r.top + margin + rng.nextDouble() * (r.height - 2 * margin),
      );
    });
  }

  // ------------------------------------------------------------- living things

  /// A round-canopy tree. [health] 0..1 controls canopy size and color.
  static void tree(
    Canvas c,
    Offset base,
    double size, {
    double health = 1,
    bool fruit = false,
    Color fruitColor = AppColors.orangeFruit,
    Color leafColor = AppColors.leaf,
  }) {
    final h = clamp01(health);
    final trunk = Path()
      ..moveTo(base.dx - size * 0.07, base.dy)
      ..lineTo(base.dx - size * 0.04, base.dy - size * 0.55)
      ..lineTo(base.dx + size * 0.04, base.dy - size * 0.55)
      ..lineTo(base.dx + size * 0.07, base.dy)
      ..close();
    // Ground shadow.
    c.drawOval(
      Rect.fromCenter(center: base, width: size * 0.9, height: size * 0.18),
      fill(AppColors.ink.withValues(alpha: 0.12)),
    );
    outlined(c, trunk, const Color(0xFF8A6242));
    final canopyR = size * (0.28 + 0.2 * h);
    final centre = Offset(base.dx, base.dy - size * 0.62);
    final leaf = AppColors.faded(leafColor, h);
    final canopy = Path()
      ..addOval(Rect.fromCircle(center: centre.translate(-canopyR * 0.45, canopyR * 0.15), radius: canopyR * 0.7))
      ..addOval(Rect.fromCircle(center: centre.translate(canopyR * 0.45, canopyR * 0.2), radius: canopyR * 0.68))
      ..addOval(Rect.fromCircle(center: centre.translate(0, -canopyR * 0.25), radius: canopyR * 0.8));
    final merged = Path.combine(PathOperation.union, Path(), canopy);
    outlined(c, merged, leaf);
    // Highlight dabs.
    final dab = fill(Color.lerp(leaf, AppColors.lime, 0.25) ?? leaf);
    c.drawCircle(centre.translate(-canopyR * 0.3, -canopyR * 0.4), canopyR * 0.16, dab);
    c.drawCircle(centre.translate(canopyR * 0.35, -canopyR * 0.05), canopyR * 0.12, dab);
    if (fruit && h > 0.45) {
      final n = (h * 7).round();
      final rng = math.Random(base.dx.round() * 31 + base.dy.round());
      for (var i = 0; i < n; i++) {
        final a = rng.nextDouble() * math.pi * 2;
        final d = rng.nextDouble() * canopyR * 0.75;
        circle(c, centre.translate(math.cos(a) * d, math.sin(a) * d * 0.8), size * 0.035, fruitColor,
            stroke: 0.8);
      }
    }
  }

  /// Olive tree: silvery, twisted trunk, narrow leaves.
  static void olive(Canvas c, Offset base, double size, {double health = 1}) {
    final h = clamp01(health);
    c.drawOval(Rect.fromCenter(center: base, width: size * 0.9, height: size * 0.16),
        fill(AppColors.ink.withValues(alpha: 0.12)));
    final trunk = Path()
      ..moveTo(base.dx - size * 0.1, base.dy)
      ..cubicTo(base.dx - size * 0.02, base.dy - size * 0.2, base.dx - size * 0.16,
          base.dy - size * 0.35, base.dx - size * 0.03, base.dy - size * 0.5)
      ..lineTo(base.dx + size * 0.05, base.dy - size * 0.48)
      ..cubicTo(base.dx - size * 0.04, base.dy - size * 0.3, base.dx + size * 0.08,
          base.dy - size * 0.2, base.dx + size * 0.1, base.dy)
      ..close();
    outlined(c, trunk, const Color(0xFF7D6A55));
    final leaf = AppColors.faded(const Color(0xFF8D9B5E), h);
    final centre = Offset(base.dx, base.dy - size * 0.62);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + (i - 2) * 0.7;
      final o = centre.translate(math.cos(a) * size * 0.2, math.sin(a) * size * 0.12 + size * 0.05);
      final blob = Path()
        ..addOval(Rect.fromCenter(center: o, width: size * (0.3 + 0.12 * h), height: size * 0.2));
      outlined(c, blob, leaf, stroke: 1.1);
    }
  }

  /// Terracotta pot with a plant. [health] < 0.3 draws a wilted plant.
  static void potPlant(
    Canvas c,
    Offset base,
    double s, {
    double health = 1,
    Color flower = const Color(0xFFD9483B),
  }) {
    final h = clamp01(health);
    final pot = Path()
      ..moveTo(base.dx - s * 0.5, base.dy - s * 0.7)
      ..lineTo(base.dx + s * 0.5, base.dy - s * 0.7)
      ..lineTo(base.dx + s * 0.38, base.dy)
      ..lineTo(base.dx - s * 0.38, base.dy)
      ..close();
    if (h < 0.3) {
      // Wilted: a few drooping brown stems.
      final stem = ink(1.3, const Color(0xFF8A6A3E));
      c.drawLine(base.translate(0, -s * 0.7), base.translate(-s * 0.3, -s * 1.1), stem);
      c.drawLine(base.translate(0, -s * 0.7), base.translate(s * 0.35, -s * 1.0), stem);
    } else {
      final leaf = AppColors.faded(AppColors.leaf, h);
      final bush = Path()
        ..addOval(Rect.fromCenter(
            center: base.translate(0, -s * (0.95 + 0.25 * h)), width: s * (0.9 + 0.5 * h), height: s * (0.6 + 0.4 * h)));
      outlined(c, bush, leaf, stroke: 1.1);
      if (h > 0.55) {
        final n = (h * 5).round();
        for (var i = 0; i < n; i++) {
          final dx = (i - (n - 1) / 2) * s * 0.22;
          circle(c, base.translate(dx, -s * (1.05 + 0.25 * h) - (i.isEven ? s * 0.12 : 0)), s * 0.1,
              flower,
              stroke: 0.7);
        }
      }
    }
    outlined(c, pot, AppColors.terracotta, stroke: 1.2);
    c.drawLine(base.translate(-s * 0.47, -s * 0.55), base.translate(s * 0.47, -s * 0.55), ink(1));
  }

  /// A herb row in the garden.
  static void herbRow(Canvas c, Offset start, double length, double health, {Color flower = const Color(0xFF9B86C8)}) {
    final h = clamp01(health);
    final n = (length / 12).floor();
    for (var i = 0; i < n; i++) {
      final p = start.translate(i * 12.0 + 6, 0);
      final leaf = AppColors.faded(AppColors.leafDark, h);
      final tuft = Path()
        ..moveTo(p.dx - 5, p.dy)
        ..quadraticBezierTo(p.dx - 4, p.dy - 9 * (0.5 + h), p.dx, p.dy - 11 * (0.5 + h))
        ..quadraticBezierTo(p.dx + 4, p.dy - 9 * (0.5 + h), p.dx + 5, p.dy)
        ..close();
      outlined(c, tuft, leaf, stroke: 1);
      if (h > 0.7) circle(c, p.translate(0, -11 * (0.5 + h)), 1.8, flower, stroke: 0);
    }
  }

  /// Butterfly with flapping wings ([flap] 0..1).
  static void butterfly(Canvas c, Offset o, double s, double flap, Color color) {
    final open = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(flap * math.pi * 2));
    for (final side in [-1.0, 1.0]) {
      final upper = Path()
        ..addOval(Rect.fromCenter(
            center: o.translate(side * s * 0.45 * open, -s * 0.2), width: s * 0.9 * open, height: s * 0.8));
      final lower = Path()
        ..addOval(Rect.fromCenter(
            center: o.translate(side * s * 0.35 * open, s * 0.3), width: s * 0.6 * open, height: s * 0.55));
      outlined(c, upper, color, stroke: 0.9);
      outlined(c, lower, Color.lerp(color, AppColors.ochre, 0.4) ?? color, stroke: 0.9);
    }
    c.drawLine(o.translate(0, -s * 0.45), o.translate(0, s * 0.55), ink(1.6));
  }

  /// The street cat that returns when a zone is Full of Life.
  static void cat(Canvas c, Offset base, double s, {Color color = const Color(0xFFE39B4A)}) {
    final body = Path()..addOval(Rect.fromCenter(center: base.translate(0, -s * 0.35), width: s * 0.9, height: s * 0.7));
    final head = Path()..addOval(Rect.fromCircle(center: base.translate(s * 0.35, -s * 0.85), radius: s * 0.28));
    final ears = Path()
      ..moveTo(base.dx + s * 0.16, base.dy - s * 1.0)
      ..lineTo(base.dx + s * 0.2, base.dy - s * 1.25)
      ..lineTo(base.dx + s * 0.33, base.dy - s * 1.08)
      ..moveTo(base.dx + s * 0.4, base.dy - s * 1.1)
      ..lineTo(base.dx + s * 0.55, base.dy - s * 1.25)
      ..lineTo(base.dx + s * 0.58, base.dy - s * 0.98);
    final tail = Path()
      ..moveTo(base.dx - s * 0.4, base.dy - s * 0.3)
      ..quadraticBezierTo(base.dx - s * 0.85, base.dy - s * 0.4, base.dx - s * 0.7, base.dy - s * 0.9);
    c.drawPath(tail, ink(s * 0.14, AppColors.ink));
    c.drawPath(tail, ink(s * 0.09, color));
    outlined(c, body, color, stroke: 1.1);
    outlined(c, ears, color, stroke: 1.1);
    outlined(c, head, color, stroke: 1.1);
    c.drawCircle(base.translate(s * 0.28, -s * 0.88), s * 0.035, fill(AppColors.ink));
    c.drawCircle(base.translate(s * 0.45, -s * 0.88), s * 0.035, fill(AppColors.ink));
  }

  // ----------------------------------------------------------- street objects

  /// Litter: 0 bottle, 1 can, 2 crumpled paper, 3 plastic bag, 4 wrapper.
  static void litter(Canvas c, Offset o, int kind, double rotation, {double s = 1}) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(rotation);
    c.scale(s);
    switch (kind % 5) {
      case 0:
        rrect(c, const Rect.fromLTWH(-6, -2.5, 10, 5), 2, const Color(0xFFBFE0E4), stroke: 1);
        rrect(c, const Rect.fromLTWH(4, -1.5, 3, 3), 1, AppColors.doorBlue, stroke: 0.8);
      case 1:
        rrect(c, const Rect.fromLTWH(-3, -4, 6, 8), 1.5, const Color(0xFFD9483B), stroke: 1);
      case 2:
        final p = Path()
          ..moveTo(-4, -3)
          ..lineTo(1, -5)
          ..lineTo(5, -1)
          ..lineTo(3, 4)
          ..lineTo(-3, 4)
          ..lineTo(-5, 0)
          ..close();
        outlined(c, p, AppColors.lime, stroke: 1);
      case 3:
        final p = Path()
          ..moveTo(-6, 3)
          ..quadraticBezierTo(-7, -6, 0, -5)
          ..quadraticBezierTo(7, -6, 6, 3)
          ..quadraticBezierTo(0, 6, -6, 3)
          ..close();
        outlined(c, p, const Color(0xFFF2F0EA), stroke: 1);
      default:
        rrect(c, const Rect.fromLTWH(-5, -3, 10, 6), 1, AppColors.ochre, stroke: 1);
    }
    c.restore();
  }

  static void bench(Canvas c, Rect r, double vitality) {
    final wood = AppColors.faded(const Color(0xFFB07A4B), vitality);
    rrect(c, r, 2, wood, stroke: 1.2);
    c.drawLine(Offset(r.left + 2, r.center.dy), Offset(r.right - 2, r.center.dy), ink(0.8));
  }

  static void padlock(Canvas c, Offset o, double s) {
    final shackle = Path()
      ..addArc(Rect.fromCenter(center: o.translate(0, -s * 0.35), width: s * 0.7, height: s * 0.8), math.pi, math.pi);
    c.drawPath(shackle, ink(s * 0.14, AppColors.ink));
    c.drawLine(o.translate(-s * 0.35, -s * 0.35), o.translate(-s * 0.35, -s * 0.1), ink(s * 0.14));
    c.drawLine(o.translate(s * 0.35, -s * 0.35), o.translate(s * 0.35, -s * 0.1), ink(s * 0.14));
    rrect(c, Rect.fromCenter(center: o.translate(0, s * 0.15), width: s, height: s * 0.7), s * 0.12,
        AppColors.ochre,
        stroke: 1.6);
    c.drawCircle(o.translate(0, s * 0.12), s * 0.08, fill(AppColors.ink));
  }

  /// Festival lanterns strung between two points.
  static void stringLights(Canvas c, Offset a, Offset b, double sag, double t) {
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + sag);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    c.drawPath(path, ink(1, AppColors.inkSoft));
    const colors = [AppColors.ochre, AppColors.terracotta, AppColors.turquoise, AppColors.bougainvillea];
    for (final metric in path.computeMetrics()) {
      final n = (metric.length / 16).floor();
      for (var i = 1; i < n; i++) {
        final tangent = metric.getTangentForOffset(metric.length * i / n);
        if (tangent == null) continue;
        final glow = 0.75 + 0.25 * math.sin((t * 2 + i * 0.37) * math.pi * 2);
        final col = colors[i % colors.length].withValues(alpha: glow);
        rrect(c, Rect.fromCenter(center: tangent.position.translate(0, 4), width: 5, height: 7), 2, col,
            stroke: 0.8);
      }
    }
  }
}
