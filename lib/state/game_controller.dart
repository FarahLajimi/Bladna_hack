import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/models/app_settings.dart';
import '../data/models/labeled_photo.dart';
import '../data/models/player_progress.dart';
import '../data/models/waste_category.dart';
import '../data/models/waste_item.dart';
import '../data/models/world.dart';
import '../data/repositories/progress_repository.dart';
import '../domain/game_engine.dart';
import '../domain/world_rules.dart';

/// The single source of game state. Widgets read it through Provider;
/// every rule lives in [GameEngine].
class GameController extends ChangeNotifier {
  GameController({
    required ProgressRepository repository,
    GameEngine engine = const GameEngine(),
    DateTime Function()? clock,
  })  : _repository = repository,
        _engine = engine,
        _clock = clock ?? DateTime.now {
    _progress = _repository.loadProgress();
    _settings = _repository.loadSettings();
  }

  final ProgressRepository _repository;
  final GameEngine _engine;
  final DateTime Function() _clock;

  late PlayerProgress _progress;
  late AppSettings _settings;
  Future<void> _lastSave = Future<void>.value();
  final StreamController<String> _achievementEvents = StreamController<String>.broadcast();

  /// Sites revealed by the most recent action (the map pulses them).
  List<String> _justRevealed = const [];

  PlayerProgress get progress => _progress;
  AppSettings get settings => _settings;
  GameEngine get engine => _engine;
  List<String> get justRevealed => _justRevealed;
  Stream<String> get achievementUnlocks => _achievementEvents.stream;
  Future<void> get saved => _lastSave;
  DateTime now() => _clock();

  // ---------------------------------------------------------------- actions

  void startJourney() => _apply(_engine.startJourney(_progress, _clock()));

  SortOutcome sort(WasteItem item, WasteCategory chosen, {required int previousWrong}) {
    final r = _engine.sortItem(_progress, item, chosen, previousWrong: previousWrong, now: _clock());
    _apply(r.outcome);
    return r;
  }

  MissionResult completeTrace(String id, List<LatLng> ring) => _mission(_engine.completeTrace(_progress, id, ring, _clock()));
  MissionResult completeMeasure(String id, LatLng a, LatLng b) =>
      _mission(_engine.completeMeasure(_progress, id, a, b, _clock()));
  MissionResult completeTimeMachine(String id, List<LatLng> pins) =>
      _mission(_engine.completeTimeMachine(_progress, id, pins, _clock()));
  MissionResult completeQuiz(String id, List<int> answers) => _mission(_engine.completeQuiz(_progress, id, answers, _clock()));
  MissionResult completeLandCover(String id, List<LandCoverClass> answers) =>
      _mission(_engine.completeLandCover(_progress, id, answers, _clock()));

  GameOutcome addFieldRecord(LabeledPhoto record) {
    final o = _engine.addFieldRecord(_progress, record, _clock());
    _apply(o);
    return o;
  }

  GameOutcome removeFieldRecord(String id) {
    final o = _engine.removeFieldRecord(_progress, id, _clock());
    _apply(o);
    return o;
  }

  GameOutcome removeAnnotation(String id) {
    final o = _engine.removeAnnotation(_progress, id, _clock());
    _apply(o);
    return o;
  }

  /// Clears all progress (settings and session are kept).
  Future<void> resetProgress() async {
    await _lastSave;
    await _repository.clearProgress();
    _progress = _engine.freshProgress();
    _justRevealed = const [];
    notifyListeners();
  }

  void updateSettings(AppSettings next) {
    _settings = next;
    notifyListeners();
    unawaited(_repository.saveSettings(next));
  }

  // ---------------------------------------------------------------- queries

  MissionState stateOf(Mission m) => WorldRules.stateOf(_progress, m);
  bool isRevealed(RealSite s) => WorldRules.isRevealed(_progress, s);
  Mission? get nextMission => WorldRules.nextMission(_progress);

  // --------------------------------------------------------------- internal

  MissionResult _mission(MissionResult r) {
    _apply(r.outcome);
    return r;
  }

  void _apply(GameOutcome outcome) {
    if (!outcome.applied && identical(outcome.progress, _progress)) return;
    _progress = outcome.progress;
    if (outcome.revealedSites.isNotEmpty) _justRevealed = outcome.revealedSites;
    for (final id in outcome.newAchievements) {
      _achievementEvents.add(id);
    }
    final snapshot = _progress;
    _lastSave = _lastSave.then((_) => _repository.saveProgress(snapshot));
    notifyListeners();
  }

  @override
  void dispose() {
    _achievementEvents.close();
    super.dispose();
  }
}
