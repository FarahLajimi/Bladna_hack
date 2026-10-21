import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/world.dart';

/// How a place looks on the map — always shape + text, never color alone.
enum SiteVisual {
  /// Not revealed yet: a muted "?" clue without a name.
  hidden,

  /// Revealed with missions to do: survey-orange, gently pulsing.
  open,

  /// Every mission done: restoration green with a check.
  explored,
}

class SiteMarker extends StatelessWidget {
  const SiteMarker({
    super.key,
    required this.site,
    required this.visual,
    required this.selected,
    required this.done,
    required this.total,
    required this.pulse,
    required this.onTap,
    this.justRevealed = false,
  });

  final RealSite site;
  final SiteVisual visual;
  final bool selected;
  final int done;
  final int total;

  /// Looping 0..1 animation (null = still, e.g. reduced motion).
  final Animation<double>? pulse;
  final VoidCallback onTap;
  final bool justRevealed;

  @override
  Widget build(BuildContext context) {
    final (Color fill, IconData icon) = switch (visual) {
      SiteVisual.hidden => (AppColors.midnightSoft, Icons.question_mark_rounded),
      SiteVisual.open => (AppColors.action, Icons.travel_explore_rounded),
      SiteVisual.explored => (AppColors.restored, Icons.check_rounded),
    };
    final label = visual == SiteVisual.hidden ? 'Unrevealed' : site.name;
    final semantics = visual == SiteVisual.hidden
        ? 'Unrevealed place. ${site.revealHint}'
        : '${site.name}. $done of $total missions done.${selected ? ' Selected.' : ''}';

    final dot = Container(
      width: selected ? 34 : 28,
      height: selected ? 34 : 28,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: selected ? 3 : 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, size: selected ? 18 : 15, color: Colors.white),
    );

    Widget ring(double t) {
      final r = 30.0 + 22 * t;
      return IgnorePointer(
        child: Container(
          width: r,
          height: r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: fill.withValues(alpha: (1 - t) * 0.9), width: 2.5),
          ),
        ),
      );
    }

    final showRing = visual == SiteVisual.open || justRevealed;
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('site-${site.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showRing && pulse != null)
                    AnimatedBuilder(animation: pulse!, builder: (_, __) => ring(pulse!.value))
                  else if (showRing)
                    ring(0.4),
                  dot,
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.midnight.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                visual == SiteVisual.hidden || total == 0 ? label : '$label · $done/$total',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.data.copyWith(color: AppColors.onDark, fontSize: 10.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A personal annotation: small rotated square ("my observation").
class AnnotationMarker extends StatelessWidget {
  const AnnotationMarker({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'My map annotation',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.limestone,
                border: Border.all(color: AppColors.midnight, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertex / pin placed during an on-map task.
class TaskPoint extends StatelessWidget {
  const TaskPoint({super.key, required this.index, this.color = AppColors.action});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        alignment: Alignment.center,
        child: Text('$index', style: AppText.data.copyWith(color: Colors.white, fontSize: 10, height: 1)),
      ),
    );
  }
}
