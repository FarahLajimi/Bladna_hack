import '../data/local_data/world_data.dart';
import '../data/models/player_progress.dart';
import '../data/models/world.dart';

enum MissionState { locked, available, done }

/// Pure rules for exploration: what is revealed, unlocked or done.
class WorldRules {
  static bool isRevealed(PlayerProgress p, RealSite site) =>
      site.revealedBy.isEmpty || site.revealedBy.any(p.isMissionDone);

  static bool isRevealedId(PlayerProgress p, String siteId) => isRevealed(p, siteById(siteId));

  static MissionState stateOf(PlayerProgress p, Mission m) {
    if (p.isMissionDone(m.id)) return MissionState.done;
    if (!isRevealedId(p, m.siteId)) return MissionState.locked;
    if (!m.requires.every(p.isMissionDone)) return MissionState.locked;
    return MissionState.available;
  }

  static Set<String> revealedSites(PlayerProgress p) =>
      {for (final s in kSites) if (isRevealed(p, s)) s.id};

  /// done / total missions at a site.
  static (int, int) siteProgress(PlayerProgress p, String siteId) {
    final ms = missionsAt(siteId);
    return (ms.where((m) => p.isMissionDone(m.id)).length, ms.length);
  }

  static bool siteComplete(PlayerProgress p, String siteId) {
    final (done, total) = siteProgress(p, siteId);
    return total > 0 && done == total;
  }

  /// The next thing to do: an available mission, preferring revealed order.
  static Mission? nextMission(PlayerProgress p) {
    for (final m in kMissions) {
      if (stateOf(p, m) == MissionState.available) return m;
    }
    return null;
  }

  /// Stars for a quiz: all correct → 3, ≥ 2/3 → 2, ≥ 1/2 → 1, otherwise 0.
  static int quizStars(int correct, int total) {
    if (total <= 0) return 0;
    if (correct >= total) return 3;
    if (correct * 3 >= total * 2) return 2;
    if (correct * 2 >= total) return 1;
    return 0;
  }
}
