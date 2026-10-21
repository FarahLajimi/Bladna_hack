import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A quiet topographic motif (nested, wobbly contour rings) used as the one
/// decorative brand element on the welcome screen.
class ContourMotif extends StatelessWidget {
  const ContourMotif({super.key, this.size = 300, this.opacity = 0.1, this.color = AppColors.midnight});

  final double size;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(size: Size.square(size), painter: _ContourPainter(color.withValues(alpha: opacity))),
      ),
    );
  }
}

class _ContourPainter extends CustomPainter {
  _ContourPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.55, size.height * 0.45);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var ring = 1; ring <= 9; ring++) {
      final base = ring * size.width / 20;
      final path = Path();
      const steps = 72;
      for (var i = 0; i <= steps; i++) {
        final a = i / steps * math.pi * 2;
        final wobble = 1 + 0.08 * math.sin(a * 3 + ring * 0.7) + 0.05 * math.cos(a * 5 - ring);
        final p = c + Offset(math.cos(a) * base * wobble * 1.15, math.sin(a) * base * wobble);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContourPainter oldDelegate) => oldDelegate.color != color;
}
