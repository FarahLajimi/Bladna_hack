import 'dart:math' as math;

import 'package:bladna/data/local_data/waste_items_data.dart';
import 'package:bladna/data/models/player_progress.dart';
import 'package:bladna/domain/game_engine.dart';
import 'package:latlong2/latlong.dart';

const engine = GameEngine();
final now = DateTime(2026, 10, 21, 10, 30);

PlayerProgress startedPlayer() => engine.startJourney(engine.freshProgress(), now).progress;

/// Sorts [count] not-yet-learned items correctly on the first try.
PlayerProgress learn(PlayerProgress p, int count) {
  var progress = p;
  for (final item in kWasteItems.where((i) => !p.masteredItems.contains(i.id)).take(count)) {
    progress = engine.sortItem(progress, item, item.category, previousWrong: 0, now: now).outcome.progress;
  }
  return progress;
}

/// A square ring of [sideMeters] centered on [c] (area ≈ side²).
List<LatLng> square(LatLng c, double sideMeters) {
  final dLat = sideMeters / 2 / 111195.0;
  final dLon = sideMeters / 2 / (111195.0 * math.cos(c.latitude * math.pi / 180));
  return [
    LatLng(c.latitude - dLat, c.longitude - dLon),
    LatLng(c.latitude - dLat, c.longitude + dLon),
    LatLng(c.latitude + dLat, c.longitude + dLon),
    LatLng(c.latitude + dLat, c.longitude - dLon),
  ];
}
