import 'package:flutter/material.dart';

/// BLADNA color system — "a field instrument for reading the land".
///
/// Interface: midnight ink + limestone surfaces, one survey-orange accent for
/// action and selection, vegetation green reserved for restoration/completion,
/// amber for environmental warnings. Floating controls are midnight with a
/// light hairline so they stay readable over both bright sand and dark sea
/// imagery.
class AppColors {
  // ---- Core interface ----
  static const midnight = Color(0xFF0F1B2D); // primary surfaces & text
  static const midnightSoft = Color(0xFF1C2B42); // raised dark surfaces
  static const limestone = Color(0xFFF5F1E8); // light surfaces, sheets
  static const mineral = Color(0xFFE6DDCB); // dividers, quiet fills
  static const earth = Color(0xFF9A7652); // satellite-earth accent (sparingly)

  // ---- Semantic ----
  static const action = Color(0xFFE2672B); // primary action, map selection
  static const actionDeep = Color(0xFFB84C18);
  static const secondary = Color(0xFF2C7F8C); // secondary action, water
  static const restored = Color(0xFF4E8A4A); // completed / ecological restoration
  static const warning = Color(0xFFD99A2B); // environmental warning
  static const disabled = Color(0xFFA9ADB3);
  static const scrim = Color(0xB30F1B2D); // overlay over imagery (70 %)

  // ---- Text ----
  static const ink = midnight;
  static const inkSoft = Color(0xFF4A5568);
  static const inkFaint = Color(0xFF7D8592);
  static const onDark = Color(0xFFF5F1E8);
  static const onDarkSoft = Color(0xFFB8C0CC);

  // ---- Legacy names used by the hand-drawn sorting illustrations ----
  static const cream = limestone;
  static const paper = Color(0xFFFFFDF8);
  static const sand = mineral;
  static const sandDeep = Color(0xFFD2C3A4);
  static const stone = Color(0xFFBDB29C);
  static const lime = Color(0xFFFFFEFA);
  static const terracotta = action;
  static const terracottaDeep = actionDeep;
  static const ochre = warning;
  static const doorBlue = Color(0xFF2B5E8C);
  static const turquoise = secondary;
  static const sea = Color(0xFF6AAFB4);
  static const seaDeep = Color(0xFF2F7F86);
  static const olive = Color(0xFF66783A);
  static const leaf = Color(0xFF6FAA5E);
  static const leafDark = Color(0xFF4E6B2E);
  static const bougainvillea = Color(0xFFB4496E);
  static const flamingo = Color(0xFFD9879A);
  static const jasmine = Color(0xFFFFF7E0);
  static const orangeFruit = Color(0xFFF08A24);
  static const success = restored;
  static const gentleError = Color(0xFFB4492E);
  static const dust = Color(0xFFB9AE9E);

  static Color faded(Color c, double vitality) {
    final double v = vitality < 0 ? 0.0 : (vitality > 1 ? 1.0 : vitality);
    return Color.lerp(dust, c, 0.35 + 0.65 * v) ?? c;
  }
}
