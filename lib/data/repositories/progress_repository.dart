import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../local_data/achievements_data.dart';
import '../local_data/waste_items_data.dart';
import '../local_data/world_data.dart';
import '../models/app_settings.dart';
import '../models/player_progress.dart';

/// Local, offline persistence using shared_preferences.
///
/// Progress is one versioned JSON document. Schema 1 (the earlier Butterfly
/// Block prototype) is migrated on load. Unreadable data is moved to a
/// backup key and the game starts fresh instead of crashing.
class ProgressRepository {
  ProgressRepository(this._prefs);

  static const String progressKey = 'bladna.progress.v1';
  static const String settingsKey = 'bladna.settings.v1';
  static const String unreadableBackupKey = 'bladna.progress.unreadable';

  final SharedPreferences _prefs;

  SharedPreferences get prefs => _prefs;

  static Future<ProgressRepository> open() async => ProgressRepository(await SharedPreferences.getInstance());

  PlayerProgress loadProgress() {
    final raw = _prefs.getString(progressKey);
    if (raw == null || raw.isEmpty) return PlayerProgress.initial();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) throw const FormatException('not an object');
      final version = decoded['v'];
      if (version is! int || version < 1 || version > PlayerProgress.schemaVersion) {
        throw const FormatException('unsupported version');
      }
      return _sanitize(PlayerProgress.fromJson(decoded));
    } catch (_) {
      _prefs.setString(unreadableBackupKey, raw);
      return PlayerProgress.initial();
    }
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    await _prefs.setString(progressKey, jsonEncode(progress.toJson()));
  }

  Future<void> clearProgress() async {
    await _prefs.remove(progressKey);
  }

  AppSettings loadSettings() {
    final raw = _prefs.getString(settingsKey);
    if (raw == null) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return AppSettings.fromJson(decoded);
    } catch (_) {
      // Fall through to defaults.
    }
    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(settingsKey, jsonEncode(settings.toJson()));
  }

  /// Drops ids that no longer exist in the content and clamps values.
  PlayerProgress _sanitize(PlayerProgress p) {
    final itemIds = kWasteItems.map((i) => i.id).toSet();
    final achievementIds = kAchievements.map((a) => a.id).toSet();
    final stars = <String, int>{};
    p.missionStars.forEach((id, v) {
      if (missionById(id) != null && v > 0) stars[id] = v > 3 ? 3 : v;
    });
    return p.copyWith(
      xp: p.xp < 0 ? 0 : p.xp,
      masteredItems: Set.unmodifiable(p.masteredItems.where(itemIds.contains)),
      firstTryItems: Set.unmodifiable(p.firstTryItems.where(itemIds.contains)),
      missionStars: Map.unmodifiable(stars),
      achievements: Map.unmodifiable(
          Map.fromEntries(p.achievements.entries.where((e) => achievementIds.contains(e.key)))),
    );
  }
}
