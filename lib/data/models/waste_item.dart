import 'waste_category.dart';

/// Which hand-drawn illustration the item uses (see WasteItemPainter).
enum ItemShape {
  bottle,
  can,
  tin,
  jar,
  glassBottle,
  brokenGlass,
  mirror,
  box,
  newspaper,
  paperBag,
  eggCarton,
  pizzaBox,
  yogurtPot,
  detergent,
  juiceCarton,
  peel,
  scraps,
  grounds,
  bread,
  eggshell,
  tissue,
  chipPacket,
  cigarette,
  battery,
  cable,
  medicine,
  paintTin,
  plate,
}

/// A single item in the sorting mini-game. Content lives in
/// `lib/data/local_data/waste_items_data.dart` so new items need no UI code.
class WasteItem {
  const WasteItem({
    required this.id,
    required this.name,
    required this.category,
    required this.explanation,
    required this.shape,
    this.mistakeHint,
    this.dependsOnLocalRules = false,
    this.safetyNote,
    this.zoneId,
  });

  final String id;
  final String name;
  final WasteCategory category;

  /// Why the correct choice is correct (shown after a correct answer).
  final String explanation;

  /// A gentle hint about a common mistake (shown after a wrong attempt).
  final String? mistakeHint;

  /// True when real-world handling depends on municipal collection rules.
  final bool dependsOnLocalRules;

  /// Extra safety guidance for hazardous items.
  final String? safetyNote;

  /// Optional link to a neighborhood zone (used for flavour text).
  final String? zoneId;

  final ItemShape shape;
}
