import '../core/constants/game_rules.dart';

/// Pure helpers for player levels.
class Progression {
  /// 1-based player level for a total XP value.
  static int levelFor(int xp) {
    var level = 1;
    for (var i = 0; i < GameRules.levelThresholds.length; i++) {
      if (xp >= GameRules.levelThresholds[i]) level = i + 1;
    }
    return level;
  }

  static String titleFor(int level) {
    final last = GameRules.levelTitles.length - 1;
    final int i = level < 1 ? 0 : (level - 1 > last ? last : level - 1);
    return GameRules.levelTitles[i];
  }

  static bool isMaxLevel(int level) => level >= GameRules.levelThresholds.length;

  /// Fraction of the way from the current level to the next (1.0 at max).
  static double levelFraction(int xp) {
    final level = levelFor(xp);
    if (isMaxLevel(level)) return 1.0;
    final start = GameRules.levelThresholds[level - 1];
    final end = GameRules.levelThresholds[level];
    return ((xp - start) / (end - start)).clamp(0.0, 1.0).toDouble();
  }

  static int xpToNext(int xp) {
    final level = levelFor(xp);
    if (isMaxLevel(level)) return 0;
    return GameRules.levelThresholds[level] - xp;
  }
}
