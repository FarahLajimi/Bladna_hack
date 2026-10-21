import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../state/game_controller.dart';

/// Reduced-motion check: the in-app setting OR the system accessibility
/// option ("remove animations").
class MotionPrefs {
  static bool reduced(BuildContext context) {
    final system = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final app = context.select<GameController, bool>((c) => c.settings.reduceMotion);
    return system || app;
  }

  static Duration duration(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;
}
