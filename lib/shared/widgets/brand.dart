import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum MarkVariant {
  /// Midnight pin, limestone contours (on light backgrounds).
  standard,

  /// Limestone pin, midnight contours (on midnight backgrounds, app icon).
  onDark,

  /// Single color (watermarks, stamps, small UI).
  mono,
}

/// The BLADNA mark: a survey pin whose body is a small terrain. Irregular
/// contour lines climb to a leaf at the summit; the orange dot is the
/// surveyed coordinate the pin points at. Same geometry as
/// assets/brand/mark.svg (100 × 100 design grid).
class BladnaMark extends StatelessWidget {
  const BladnaMark({
    super.key,
    this.size = 40,
    this.variant = MarkVariant.standard,
    this.monoColor = AppColors.midnight,
    this.drawProgress = 1,
  });

  final double size;
  final MarkVariant variant;
  final Color monoColor;

  /// 0..1 — contours and leaf "draw in" (used by the splash).
  final double drawProgress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BLADNA logo',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(variant: variant, monoColor: monoColor, t: drawProgress),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.variant, required this.monoColor, required this.t});

  final MarkVariant variant;
  final Color monoColor;
  final double t;

  static Path pin() => Path()
    ..moveTo(50, 88)
    ..cubicTo(40, 74, 21, 62, 21, 41)
    ..arcToPoint(const Offset(79, 41), radius: const Radius.circular(29), largeArc: true, clockwise: true)
    ..cubicTo(79, 62, 60, 74, 50, 88)
    ..close();

  static Path outer() => Path()
    ..moveTo(28.5, 49)
    ..cubicTo(25, 38, 31, 27, 42, 24.5)
    ..cubicTo(50, 22.8, 55, 27, 61.5, 25.8)
    ..cubicTo(70, 24.5, 75.5, 33, 72.5, 42.5)
    ..cubicTo(70, 50.5, 63, 53, 57, 55.5)
    ..cubicTo(50, 58.5, 46, 57, 40, 56.5)
    ..cubicTo(34, 56, 30.5, 54.5, 28.5, 49)
    ..close();

  static Path inner() => Path()
    ..moveTo(35.5, 46)
    ..cubicTo(33.5, 38.5, 38.5, 32, 46, 31)
    ..cubicTo(51, 30.3, 54, 32.5, 58.5, 31.8)
    ..cubicTo(64.5, 31, 67.5, 36.5, 65.5, 42.5)
    ..cubicTo(63.8, 47.5, 58.5, 49.5, 53.5, 50)
    ..cubicTo(47, 50.6, 37.5, 52, 35.5, 46)
    ..close();

  static Path leaf() => Path()
    ..moveTo(42.5, 45.5)
    ..cubicTo(42.5, 37, 49.5, 32.5, 59.5, 33.5)
    ..cubicTo(60, 43, 53, 47.5, 42.5, 45.5)
    ..close();

  static Path midrib() => Path()
    ..moveTo(44, 44.2)
    ..cubicTo(48.5, 41.5, 53, 38.5, 57, 35.5);

  Path _partial(Path p, double f) {
    if (f >= 1) return p;
    final out = Path();
    for (final m in p.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * f), Offset.zero);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final (Color pinC, Color lineC, Color leafC, Color dotC) = switch (variant) {
      MarkVariant.standard => (AppColors.midnight, AppColors.limestone, const Color(0xFF6FAA5E), AppColors.action),
      MarkVariant.onDark => (AppColors.limestone, AppColors.midnight, const Color(0xFF5C9A52), AppColors.action),
      MarkVariant.mono => (monoColor, Colors.white, Colors.white, monoColor),
    };
    double seg(double from, double to) => t <= from ? 0 : (t >= to ? 1 : (t - from) / (to - from));

    canvas.drawPath(pin(), Paint()..color = pinC);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final o = seg(0.1, 0.5);
    final i = seg(0.3, 0.7);
    if (o > 0) canvas.drawPath(_partial(outer(), o), line..color = lineC.withValues(alpha: variant == MarkVariant.mono ? 1 : 0.55));
    if (i > 0) canvas.drawPath(_partial(inner(), i), line..color = lineC.withValues(alpha: variant == MarkVariant.mono ? 1 : 0.8));
    final l = seg(0.6, 0.9);
    if (l > 0) {
      canvas.save();
      canvas.translate(51, 40);
      canvas.scale(l, l);
      canvas.translate(-51, -40);
      canvas.drawPath(leaf(), Paint()..color = leafC);
      canvas.drawPath(
        midrib(),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..color = variant == MarkVariant.mono ? monoColor : (variant == MarkVariant.onDark ? AppColors.limestone : AppColors.midnight),
      );
      canvas.restore();
    }
    final d = seg(0.85, 1);
    if (d > 0) canvas.drawCircle(const Offset(50, 94.5), 3.4 * d, Paint()..color = dotC);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.t != t || old.variant != variant || old.monoColor != monoColor;
}

/// Mark + "BLADNA" wordmark (+ optional tagline).
class BladnaLockup extends StatelessWidget {
  const BladnaLockup({super.key, this.markSize = 44, this.onDark = false, this.tagline = true});

  final double markSize;
  final bool onDark;
  final bool tagline;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? AppColors.onDark : AppColors.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BladnaMark(size: markSize, variant: onDark ? MarkVariant.onDark : MarkVariant.standard),
        SizedBox(width: markSize * 0.22),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BLADNA',
                style: TextStyle(
                  fontFamily: AppText.display,
                  fontWeight: FontWeight.w700,
                  fontSize: markSize * 0.56,
                  letterSpacing: markSize * 0.08,
                  height: 1,
                  color: fg,
                )),
            if (tagline) ...[
              SizedBox(height: markSize * 0.08),
              Text('READ THE LAND · RESTORE IT',
                  style: AppText.label.copyWith(
                    fontSize: markSize * 0.18,
                    letterSpacing: markSize * 0.035,
                    color: onDark ? AppColors.onDarkSoft : AppColors.inkSoft,
                  )),
            ],
          ],
        ),
      ],
    );
  }
}
