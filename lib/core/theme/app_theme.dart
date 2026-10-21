import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type system: Space Grotesk (headings — precise, instrument-like),
/// Inter (body — compact and legible), IBM Plex Mono (coordinates, figures,
/// map labels). All bundled under assets/fonts (SIL OFL 1.1).
class AppText {
  static const display = 'SpaceGrotesk';
  static const body = 'Inter';
  static const mono = 'PlexMono';

  static const TextStyle title = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 1.12,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.2,
    color: AppColors.ink,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.25,
    color: AppColors.ink,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.45,
    color: AppColors.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.35,
    color: AppColors.ink,
  );

  static const TextStyle small = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.4,
    color: AppColors.inkSoft,
  );

  /// Overline labels ("EVIDENCE", "MISSION").
  static const TextStyle label = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 1.1,
    color: AppColors.inkSoft,
  );

  /// Coordinates, measurements, map labels.
  static const TextStyle data = TextStyle(
    fontFamily: mono,
    fontWeight: FontWeight.w500,
    fontSize: 12.5,
    height: 1.3,
    color: AppColors.inkSoft,
  );

  /// Explanations ("what you learned"). Kept for older call sites.
  static const TextStyle note = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    fontSize: 14.5,
    height: 1.45,
    color: AppColors.inkSoft,
  );
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.midnight,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.action,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.restored,
      surface: AppColors.limestone,
      onSurface: AppColors.ink,
      error: AppColors.gentleError,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppText.body,
      scaffoldBackgroundColor: AppColors.limestone,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
        fontFamily: AppText.body,
      ),
    );
  }
}
