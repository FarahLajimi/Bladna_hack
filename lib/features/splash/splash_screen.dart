import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/brand.dart';

/// Midnight field; the contours draw in, the leaf grows, the coordinate dot
/// lands. Matches the native Android launch screen color, so the hand-off
/// from the system splash is seamless. Skipped instantly with reduced motion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
    } else {
      _c.forward().whenComplete(() {
        if (!mounted) return;
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (mounted) widget.onDone();
        });
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_c.value);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BladnaMark(size: 112, variant: MarkVariant.onDark, drawProgress: t),
                const SizedBox(height: 18),
                Opacity(
                  opacity: (t * 1.6 - 0.6).clamp(0.0, 1.0).toDouble(),
                  child: Column(
                    children: [
                      Text('BLADNA',
                          style: AppText.title.copyWith(color: AppColors.onDark, fontSize: 30, letterSpacing: 6)),
                      const SizedBox(height: 6),
                      Text('READ THE LAND · RESTORE IT',
                          style: AppText.label.copyWith(color: AppColors.onDarkSoft, letterSpacing: 2.2)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
