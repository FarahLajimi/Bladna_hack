import 'dart:math' as math;

import '../core/constants/game_rules.dart';
import '../data/local_data/waste_items_data.dart';
import '../data/models/player_progress.dart';
import '../data/models/waste_category.dart';
import '../data/models/waste_item.dart';

/// Chooses which items appear in a sorting round.
///
/// Priority: unmastered items in the [focus] categories (from the mission
/// that launched the round), then other unmastered items, then already
/// mastered items as practice (which give no XP).
class SortRoundPlanner {
  static List<WasteItem> plan(
    PlayerProgress p, {
    List<WasteCategory> focus = const [],
    int size = GameRules.roundSize,
    math.Random? random,
    List<WasteItem> pool = kWasteItems,
  }) {
    final rng = random ?? math.Random();
    final focused = <WasteItem>[];
    final fresh = <WasteItem>[];
    final practice = <WasteItem>[];
    for (final item in pool) {
      if (p.masteredItems.contains(item.id)) {
        practice.add(item);
      } else if (focus.contains(item.category)) {
        focused.add(item);
      } else {
        fresh.add(item);
      }
    }
    focused.shuffle(rng);
    fresh.shuffle(rng);
    practice.shuffle(rng);
    return [...focused, ...fresh, ...practice].take(size).toList();
  }

  /// True when every item in the pool has been mastered (practice mode).
  static bool allMastered(PlayerProgress p, {List<WasteItem> pool = kWasteItems}) =>
      pool.every((i) => p.masteredItems.contains(i.id));
}
