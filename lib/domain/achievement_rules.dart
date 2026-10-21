import '../data/local_data/achievements_data.dart';
import '../data/local_data/waste_items_data.dart';
import '../data/local_data/world_data.dart';
import '../data/models/player_progress.dart';
import '../data/models/waste_category.dart';
import 'world_rules.dart';

/// Achievement conditions, evaluated only from saved game state.
class AchievementRules {
  static final Map<String, bool Function(PlayerProgress)> conditions = {
    AchievementIds.firstSteps: (p) => p.masteredItems.isNotEmpty,
    AchievementIds.carefulSorter: (p) => p.masteredItems.length >= 5,
    AchievementIds.sharpEye: (p) => p.firstTryItems.length >= 10,
    AchievementIds.safeHands: (p) =>
        p.masteredItems.any((id) => wasteItemById(id)?.category == WasteCategory.special),
    AchievementIds.fieldReady: (p) => p.isMissionDone(MissionIds.fieldTraining),
    AchievementIds.eyeInTheSky: (p) => kMissions.any((m) => m.type.onMap && p.isMissionDone(m.id)),
    AchievementIds.evidenceFirst: (p) => p.starsOf(MissionIds.evidenceFirst) >= 3,
    AchievementIds.wetlandReader: (p) => WorldRules.siteComplete(p, SiteIds.sejoumi),
    AchievementIds.cartographer: (p) => kSites.every((s) => WorldRules.isRevealed(p, s)),
    AchievementIds.geomatician: (p) => kMissions.every((m) => p.isMissionDone(m.id)),
    AchievementIds.dataGardener: (p) => p.fieldRecords.length >= 5,
  };

  static List<String> newlyEarned(PlayerProgress p) {
    final out = <String>[];
    for (final a in kAchievements) {
      final cond = conditions[a.id];
      if (cond != null && !p.achievements.containsKey(a.id) && cond(p)) out.add(a.id);
    }
    return out;
  }
}
