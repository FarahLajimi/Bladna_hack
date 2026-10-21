import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/waste_item.dart';
import '../../shared/widgets/paint_kit.dart';

/// Draws a waste item in BLADNA's sticker style on a 100 x 100 canvas.
class WasteItemPainter extends CustomPainter {
  const WasteItemPainter(this.shape);

  final ItemShape shape;

  static const _glass = Color(0xFFB7D3C9);
  static const _cardboard = Color(0xFFC79A62);
  static const _plastic = Color(0xFFBFE0E4);
  static const _metal = Color(0xFFB9BDC1);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    // Ground shadow under every item.
    canvas.drawOval(const Rect.fromLTWH(22, 86, 56, 8), Kit.fill(AppColors.ink.withValues(alpha: 0.12)));
    _draw(canvas);
    canvas.restore();
  }

  void _draw(Canvas c) {
    switch (shape) {
      case ItemShape.bottle:
        final body = Path()
          ..moveTo(40, 30)
          ..quadraticBezierTo(36, 36, 36, 44)
          ..lineTo(36, 84)
          ..quadraticBezierTo(36, 88, 40, 88)
          ..lineTo(60, 88)
          ..quadraticBezierTo(64, 88, 64, 84)
          ..lineTo(64, 44)
          ..quadraticBezierTo(64, 36, 60, 30)
          ..close();
        Kit.outlined(c, body, _plastic, stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(43, 18, 14, 13), 3, AppColors.doorBlue, stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(36, 52, 28, 16), 0, AppColors.turquoise, stroke: 1.6);
        c.drawLine(const Offset(44, 40), const Offset(44, 48), Kit.ink(2, AppColors.lime));
      case ItemShape.can:
        Kit.rrect(c, const Rect.fromLTWH(34, 24, 32, 62), 6, const Color(0xFFD9483B), stroke: 2);
        c.drawOval(const Rect.fromLTWH(34, 20, 32, 10), Kit.fill(_metal));
        c.drawOval(const Rect.fromLTWH(34, 20, 32, 10), Kit.ink(2));
        Kit.rrect(c, const Rect.fromLTWH(34, 46, 32, 12), 0, AppColors.lime, stroke: 1.4);
      case ItemShape.tin:
        Kit.rrect(c, const Rect.fromLTWH(30, 34, 40, 50), 4, _metal, stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(30, 44, 40, 28), 0, const Color(0xFFD9483B), stroke: 1.6);
        Kit.circle(c, const Offset(50, 58), 7, AppColors.orangeFruit, stroke: 1.4);
        c.drawLine(const Offset(30, 38), const Offset(70, 38), Kit.ink(1.2));
      case ItemShape.jar:
        Kit.rrect(c, const Rect.fromLTWH(32, 34, 36, 52), 9, _glass, stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(34, 24, 32, 12), 3, AppColors.terracotta, stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(38, 50, 24, 18), 2, AppColors.lime, stroke: 1.4);
        c.drawLine(const Offset(38, 42), const Offset(38, 78), Kit.ink(2, AppColors.lime));
      case ItemShape.glassBottle:
        final body = Path()
          ..moveTo(45, 16)
          ..lineTo(55, 16)
          ..lineTo(55, 36)
          ..quadraticBezierTo(66, 42, 66, 54)
          ..lineTo(66, 84)
          ..quadraticBezierTo(66, 88, 62, 88)
          ..lineTo(38, 88)
          ..quadraticBezierTo(34, 88, 34, 84)
          ..lineTo(34, 54)
          ..quadraticBezierTo(34, 42, 45, 36)
          ..close();
        Kit.outlined(c, body, const Color(0xFF8DAE6A), stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(39, 56, 22, 18), 2, AppColors.ochre, stroke: 1.4);
        c.drawLine(const Offset(40, 46), const Offset(40, 80), Kit.ink(2, AppColors.lime));
      case ItemShape.brokenGlass:
        final glass = Path()
          ..moveTo(32, 30)
          ..lineTo(68, 30)
          ..lineTo(64, 84)
          ..lineTo(36, 84)
          ..close();
        Kit.outlined(c, glass, _glass, stroke: 2);
        final crack = Kit.ink(1.6);
        c.drawLine(const Offset(46, 30), const Offset(52, 48), crack);
        c.drawLine(const Offset(52, 48), const Offset(44, 58), crack);
        c.drawLine(const Offset(52, 48), const Offset(62, 54), crack);
        final shard = Path()
          ..moveTo(70, 80)
          ..lineTo(80, 76)
          ..lineTo(76, 88)
          ..close();
        Kit.outlined(c, shard, _glass, stroke: 1.6);
      case ItemShape.mirror:
        Kit.rrect(c, const Rect.fromLTWH(30, 18, 40, 66), 18, const Color(0xFFB07A4B), stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(36, 24, 28, 54), 13, const Color(0xFFDDEBF0), stroke: 1.6);
        final crack = Kit.ink(1.4);
        c.drawLine(const Offset(40, 34), const Offset(52, 50), crack);
        c.drawLine(const Offset(52, 50), const Offset(60, 46), crack);
        c.drawLine(const Offset(52, 50), const Offset(48, 66), crack);
      case ItemShape.box:
        final front = Path()
          ..moveTo(24, 44)
          ..lineTo(62, 44)
          ..lineTo(62, 84)
          ..lineTo(24, 84)
          ..close();
        final top = Path()
          ..moveTo(24, 44)
          ..lineTo(40, 32)
          ..lineTo(78, 32)
          ..lineTo(62, 44)
          ..close();
        final side = Path()
          ..moveTo(62, 44)
          ..lineTo(78, 32)
          ..lineTo(78, 72)
          ..lineTo(62, 84)
          ..close();
        Kit.outlined(c, side, const Color(0xFFAE8250), stroke: 2);
        Kit.outlined(c, top, const Color(0xFFD8AE76), stroke: 2);
        Kit.outlined(c, front, _cardboard, stroke: 2);
        c.drawLine(const Offset(43, 44), const Offset(59, 32), Kit.ink(4, AppColors.ochre));
        c.drawLine(const Offset(30, 74), const Offset(42, 74), Kit.ink(1.4));
      case ItemShape.newspaper:
        final page = Path()
          ..moveTo(24, 28)
          ..lineTo(72, 22)
          ..lineTo(78, 78)
          ..lineTo(30, 84)
          ..close();
        Kit.outlined(c, page, const Color(0xFFF2EEE4), stroke: 2);
        final line = Kit.ink(2.4, AppColors.inkSoft);
        c.drawLine(const Offset(32, 36), const Offset(66, 32), Kit.ink(5, AppColors.ink));
        for (var i = 0; i < 5; i++) {
          c.drawLine(Offset(34, 48.0 + i * 7), Offset(52, 46.0 + i * 7), line);
        }
        Kit.rrect(c, const Rect.fromLTWH(56, 44, 14, 20), 1, AppColors.sea, stroke: 1.2);
      case ItemShape.paperBag:
        final bag = Path()
          ..moveTo(36, 22)
          ..lineTo(64, 22)
          ..lineTo(70, 86)
          ..lineTo(30, 86)
          ..close();
        Kit.outlined(c, bag, const Color(0xFFE2C591), stroke: 2);
        // Baguette peeking out.
        final bread = Path()
          ..moveTo(44, 26)
          ..quadraticBezierTo(46, 6, 56, 10)
          ..quadraticBezierTo(60, 14, 56, 26)
          ..close();
        Kit.outlined(c, bread, const Color(0xFFD99A4E), stroke: 1.8);
        c.drawLine(const Offset(36, 34), const Offset(64, 34), Kit.ink(1.2));
      case ItemShape.eggCarton:
        Kit.rrect(c, const Rect.fromLTWH(18, 46, 64, 30), 6, const Color(0xFFBFB2A0), stroke: 2);
        for (var i = 0; i < 3; i++) {
          Kit.circle(c, Offset(32.0 + i * 18, 46), 8, const Color(0xFFF4E3C8), stroke: 1.6);
        }
        for (var i = 0; i < 4; i++) {
          c.drawLine(Offset(26.0 + i * 16, 62), Offset(26.0 + i * 16, 76), Kit.ink(1.2));
        }
      case ItemShape.pizzaBox:
        Kit.rrect(c, const Rect.fromLTWH(16, 50, 68, 30), 3, _cardboard, stroke: 2);
        final lid = Path()
          ..moveTo(16, 50)
          ..lineTo(26, 22)
          ..lineTo(90, 22)
          ..lineTo(84, 50)
          ..close();
        Kit.outlined(c, lid, const Color(0xFFD8AE76), stroke: 2);
        final grease = Kit.fill(const Color(0xFF9A6A2E).withValues(alpha: 0.55));
        c.drawOval(const Rect.fromLTWH(30, 56, 18, 10), grease);
        c.drawOval(const Rect.fromLTWH(56, 60, 12, 8), grease);
        c.drawOval(const Rect.fromLTWH(46, 30, 16, 9), grease);
      case ItemShape.yogurtPot:
        final pot = Path()
          ..moveTo(30, 34)
          ..lineTo(70, 34)
          ..lineTo(64, 84)
          ..lineTo(36, 84)
          ..close();
        Kit.outlined(c, pot, AppColors.lime, stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(26, 28, 48, 8), 2, _metal, stroke: 2);
        Kit.circle(c, const Offset(50, 58), 9, const Color(0xFFE48AA6), stroke: 1.4);
      case ItemShape.detergent:
        final body = Path()
          ..moveTo(32, 36)
          ..lineTo(64, 36)
          ..quadraticBezierTo(70, 36, 70, 44)
          ..lineTo(70, 84)
          ..lineTo(32, 84)
          ..close();
        Kit.outlined(c, body, AppColors.turquoise, stroke: 2);
        final handle = Path()
          ..moveTo(52, 36)
          ..lineTo(52, 26)
          ..lineTo(66, 26)
          ..lineTo(66, 36);
        c.drawPath(handle, Kit.ink(5));
        c.drawPath(handle, Kit.ink(3, AppColors.turquoise));
        Kit.rrect(c, const Rect.fromLTWH(34, 24, 14, 12), 2, AppColors.ochre, stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(38, 50, 26, 20), 3, AppColors.lime, stroke: 1.4);
      case ItemShape.juiceCarton:
        final front = Path()
          ..moveTo(32, 36)
          ..lineTo(60, 36)
          ..lineTo(60, 86)
          ..lineTo(32, 86)
          ..close();
        final roof = Path()
          ..moveTo(32, 36)
          ..lineTo(46, 20)
          ..lineTo(60, 36)
          ..close();
        final side = Path()
          ..moveTo(60, 36)
          ..lineTo(70, 30)
          ..lineTo(70, 80)
          ..lineTo(60, 86)
          ..close();
        Kit.outlined(c, side, const Color(0xFFE7A04A), stroke: 2);
        Kit.outlined(c, front, AppColors.orangeFruit, stroke: 2);
        Kit.outlined(c, roof, AppColors.lime, stroke: 2);
        Kit.circle(c, const Offset(46, 58), 8, const Color(0xFFFFD27A), stroke: 1.4);
      case ItemShape.peel:
        for (var i = 0; i < 3; i++) {
          final a = i * 2.1;
          final o = Offset(50 + math.cos(a) * 14, 62 + math.sin(a) * 10);
          final peel = Path()
            ..addArc(Rect.fromCircle(center: o, radius: 16), a, math.pi * 1.1);
          c.drawPath(peel, Kit.ink(9));
          c.drawPath(peel, Kit.ink(6.5, AppColors.orangeFruit));
        }
      case ItemShape.scraps:
        final carrot = Path()
          ..moveTo(26, 60)
          ..lineTo(60, 52)
          ..lineTo(60, 64)
          ..close();
        Kit.outlined(c, carrot, AppColors.orangeFruit, stroke: 2);
        c.drawLine(const Offset(60, 58), const Offset(72, 48), Kit.ink(3, AppColors.leaf));
        c.drawLine(const Offset(60, 58), const Offset(74, 58), Kit.ink(3, AppColors.leaf));
        Kit.circle(c, const Offset(46, 76), 10, const Color(0xFFE9D7A8), stroke: 2);
        Kit.circle(c, const Offset(66, 74), 8, const Color(0xFF8DAE6A), stroke: 2);
      case ItemShape.grounds:
        Kit.rrect(c, const Rect.fromLTWH(26, 56, 48, 26), 12, const Color(0xFF5A3A24), stroke: 2);
        final speck = Kit.fill(const Color(0xFF3C2616));
        final rng = math.Random(4);
        for (var i = 0; i < 18; i++) {
          c.drawCircle(Offset(32 + rng.nextDouble() * 36, 60 + rng.nextDouble() * 18), 1.4, speck);
        }
        // A small coffee cup (the classic glass of the café).
        Kit.rrect(c, const Rect.fromLTWH(40, 26, 20, 22), 3, AppColors.lime, stroke: 2);
        c.drawLine(const Offset(42, 32), const Offset(58, 32), Kit.ink(1.2, AppColors.doorBlue));
      case ItemShape.bread:
        final loaf = Path()
          ..moveTo(18, 66)
          ..quadraticBezierTo(18, 48, 50, 46)
          ..quadraticBezierTo(82, 48, 82, 66)
          ..quadraticBezierTo(82, 76, 50, 76)
          ..quadraticBezierTo(18, 76, 18, 66)
          ..close();
        Kit.outlined(c, loaf, const Color(0xFFD99A4E), stroke: 2);
        final slash = Kit.ink(1.6, const Color(0xFF8A5A2B));
        c.drawLine(const Offset(32, 56), const Offset(38, 62), slash);
        c.drawLine(const Offset(46, 54), const Offset(52, 60), slash);
        c.drawLine(const Offset(60, 54), const Offset(66, 60), slash);
      case ItemShape.eggshell:
        for (final o in const [Offset(38, 64), Offset(62, 66)]) {
          final shell = Path()
            ..moveTo(o.dx - 14, o.dy - 4)
            ..lineTo(o.dx - 8, o.dy - 10)
            ..lineTo(o.dx - 2, o.dy - 4)
            ..lineTo(o.dx + 4, o.dy - 11)
            ..lineTo(o.dx + 14, o.dy - 4)
            ..quadraticBezierTo(o.dx + 14, o.dy + 14, o.dx, o.dy + 14)
            ..quadraticBezierTo(o.dx - 14, o.dy + 14, o.dx - 14, o.dy - 4)
            ..close();
          Kit.outlined(c, shell, const Color(0xFFF4E3C8), stroke: 2);
        }
      case ItemShape.tissue:
        final t = Path()
          ..moveTo(28, 56)
          ..quadraticBezierTo(30, 36, 46, 40)
          ..quadraticBezierTo(56, 28, 66, 42)
          ..quadraticBezierTo(80, 46, 72, 64)
          ..quadraticBezierTo(70, 82, 50, 78)
          ..quadraticBezierTo(28, 82, 28, 56)
          ..close();
        Kit.outlined(c, t, AppColors.lime, stroke: 2);
        c.drawLine(const Offset(42, 56), const Offset(56, 62), Kit.ink(1.2, AppColors.inkFaint));
      case ItemShape.chipPacket:
        final pack = Path()
          ..moveTo(30, 22)
          ..lineTo(70, 22)
          ..lineTo(66, 86)
          ..lineTo(34, 86)
          ..close();
        Kit.outlined(c, pack, AppColors.ochre, stroke: 2);
        for (var x = 32.0; x < 70; x += 6) {
          c.drawLine(Offset(x, 22), Offset(x + 3, 27), Kit.ink(1.2));
        }
        Kit.circle(c, const Offset(50, 56), 11, const Color(0xFFF2D06B), stroke: 1.6);
        c.drawLine(const Offset(36, 34), const Offset(40, 76), Kit.ink(2, AppColors.lime));
      case ItemShape.cigarette:
        Kit.rrect(c, const Rect.fromLTWH(22, 60, 30, 10), 2, const Color(0xFFE39B4A), stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(50, 60, 26, 10), 2, AppColors.lime, stroke: 2);
        Kit.circle(c, const Offset(78, 65), 4, AppColors.inkFaint, stroke: 1.4);
      case ItemShape.battery:
        Kit.rrect(c, const Rect.fromLTWH(26, 40, 46, 26), 5, AppColors.ink, stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(26, 40, 18, 26), 5, AppColors.ochre, stroke: 2);
        Kit.rrect(c, const Rect.fromLTWH(72, 47, 6, 12), 2, _metal, stroke: 2);
        c.drawLine(const Offset(54, 53), const Offset(64, 53), Kit.ink(2, AppColors.lime));
        c.drawLine(const Offset(59, 48), const Offset(59, 58), Kit.ink(2, AppColors.lime));
      case ItemShape.cable:
        Kit.rrect(c, const Rect.fromLTWH(26, 26, 26, 30), 5, AppColors.lime, stroke: 2);
        c.drawLine(const Offset(33, 18), const Offset(33, 26), Kit.ink(3));
        c.drawLine(const Offset(45, 18), const Offset(45, 26), Kit.ink(3));
        final wire = Path()
          ..moveTo(39, 56)
          ..cubicTo(36, 80, 70, 82, 66, 60)
          ..cubicTo(64, 46, 80, 44, 80, 60);
        c.drawPath(wire, Kit.ink(5));
        c.drawPath(wire, Kit.ink(3, AppColors.lime));
      case ItemShape.medicine:
        Kit.rrect(c, const Rect.fromLTWH(22, 40, 56, 34), 6, AppColors.lime, stroke: 2);
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 2; j++) {
            Kit.circle(c, Offset(34.0 + i * 16, 50.0 + j * 14), 5, const Color(0xFFE48AA6), stroke: 1.4);
          }
        }
        c.drawLine(const Offset(50, 20), const Offset(50, 34), Kit.ink(5, AppColors.success));
        c.drawLine(const Offset(43, 27), const Offset(57, 27), Kit.ink(5, AppColors.success));
      case ItemShape.paintTin:
        Kit.rrect(c, const Rect.fromLTWH(28, 36, 44, 48), 4, _metal, stroke: 2);
        final drip = Path()
          ..moveTo(28, 40)
          ..lineTo(72, 40)
          ..lineTo(72, 50)
          ..quadraticBezierTo(66, 50, 64, 58)
          ..quadraticBezierTo(62, 50, 54, 52)
          ..lineTo(28, 52)
          ..close();
        Kit.outlined(c, drip, AppColors.doorBlue, stroke: 1.6);
        final handle = Path()
          ..moveTo(30, 38)
          ..quadraticBezierTo(50, 14, 70, 38);
        c.drawPath(handle, Kit.ink(2));
      case ItemShape.plate:
        final half = Path()
          ..addArc(const Rect.fromLTWH(20, 36, 60, 44), math.pi * 0.1, math.pi * 1.1)
          ..lineTo(50, 58)
          ..close();
        Kit.outlined(c, half, AppColors.lime, stroke: 2);
        c.drawArc(const Rect.fromLTWH(28, 42, 44, 32), math.pi * 0.15, math.pi * 1.0, false,
            Kit.ink(2, AppColors.doorBlue));
        final shard = Path()
          ..moveTo(62, 76)
          ..lineTo(80, 70)
          ..lineTo(76, 84)
          ..close();
        Kit.outlined(c, shard, AppColors.lime, stroke: 1.8);
    }
  }

  @override
  bool shouldRepaint(covariant WasteItemPainter oldDelegate) => oldDelegate.shape != shape;
}
