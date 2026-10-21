import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/waste_category.dart';
import '../../shared/widgets/paint_kit.dart';

/// A sorting bin: a drag target AND a tap target (drag is never required).
class SortingBin extends StatelessWidget {
  const SortingBin({
    super.key,
    required this.category,
    required this.enabled,
    required this.onChosen,
    this.state = BinState.idle,
  });

  final WasteCategory category;
  final bool enabled;
  final VoidCallback onChosen;
  final BinState state;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => enabled,
      onAcceptWithDetails: (_) => onChosen(),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        final borderColor = switch (state) {
          BinState.correct => AppColors.success,
          BinState.wrong => AppColors.gentleError,
          BinState.idle => hovering ? AppColors.ochre : AppColors.ink,
        };
        return Semantics(
          button: true,
          enabled: enabled,
          label: '${category.label} bin. ${category.hint}',
          excludeSemantics: true,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            scale: hovering ? 1.06 : 1,
            child: Material(
              color: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: borderColor, width: state == BinState.idle && !hovering ? 1.6 : 3),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: enabled ? onChosen : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 46,
                        width: 46,
                        child: CustomPaint(painter: _BinPainter(category)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.shortLabel,
                        style: AppText.subheading.copyWith(fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        category.hint,
                        style: AppText.small.copyWith(fontSize: 10.5, height: 1.15),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum BinState { idle, correct, wrong }

class _BinPainter extends CustomPainter {
  const _BinPainter(this.category);

  final WasteCategory category;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 46;
    canvas.save();
    canvas.scale(s);
    final body = Path()
      ..moveTo(8, 14)
      ..lineTo(38, 14)
      ..lineTo(35, 44)
      ..lineTo(11, 44)
      ..close();
    Kit.outlined(canvas, body, category.color, stroke: 1.6);
    Kit.rrect(canvas, const Rect.fromLTWH(5, 8, 36, 7), 2, Color.lerp(category.color, AppColors.ink, 0.25) ?? category.color,
        stroke: 1.6);
    Kit.rrect(canvas, const Rect.fromLTWH(18, 4, 10, 5), 2, AppColors.inkSoft, stroke: 1.2);
    canvas.restore();
    // Category icon on the bin (same icon as everywhere else in the app).
    final icon = category.icon;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 16 * s,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, 21 * s));
  }

  @override
  bool shouldRepaint(covariant _BinPainter oldDelegate) => oldDelegate.category != category;
}
