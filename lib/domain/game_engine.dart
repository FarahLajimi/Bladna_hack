import 'package:latlong2/latlong.dart';

import '../core/constants/game_rules.dart';
import '../data/local_data/achievements_data.dart';
import '../data/local_data/world_data.dart';
import '../data/models/labeled_photo.dart';
import '../data/models/map_annotation.dart';
import '../data/models/player_progress.dart';
import '../data/models/restoration_event.dart';
import '../data/models/waste_category.dart';
import '../data/models/waste_item.dart';
import '../data/models/world.dart';
import 'achievement_rules.dart';
import 'geodesy.dart';
import 'progression.dart';
import 'world_rules.dart';

/// The result of any game action: the new state plus what changed.
class GameOutcome {
  const GameOutcome({
    required this.progress,
    required this.levelBefore,
    required this.levelAfter,
    this.applied = true,
    this.xpGained = 0,
    this.newAchievements = const [],
    this.revealedSites = const [],
    this.message,
  });

  factory GameOutcome.unchanged(PlayerProgress p, [String? message]) {
    final level = Progression.levelFor(p.xp);
    return GameOutcome(progress: p, levelBefore: level, levelAfter: level, applied: false, message: message);
  }

  final PlayerProgress progress;
  final bool applied;
  final int xpGained;
  final List<String> newAchievements;

  /// Sites revealed on the map by this action.
  final List<String> revealedSites;
  final int levelBefore;
  final int levelAfter;
  final String? message;

  bool get leveledUp => levelAfter > levelBefore;
}

/// A scored mission attempt.
class MissionResult {
  const MissionResult({
    required this.mission,
    required this.stars,
    required this.summary,
    required this.outcome,
  });

  final Mission mission;

  /// Stars earned by THIS attempt (the saved best may be higher).
  final int stars;

  /// What was measured / answered, with the reference and its source.
  final String summary;
  final GameOutcome outcome;
}

class SortOutcome {
  const SortOutcome({
    required this.item,
    required this.chosen,
    required this.correct,
    required this.wrongCount,
    required this.newlyMastered,
    required this.outcome,
  });

  final WasteItem item;
  final WasteCategory chosen;
  final bool correct;
  final int wrongCount;
  final bool newlyMastered;
  final GameOutcome outcome;

  bool get showHint => !correct && wrongCount >= GameRules.hintAfterWrong;
  bool get revealAnswer => !correct && wrongCount >= GameRules.revealAfterWrong;
}

/// Pure, deterministic game rules. Every mission is scored here from its raw
/// inputs (traced ring, measured points, answers…) so scoring is testable and
/// rewards cannot be duplicated: XP is only granted for an improvement on
/// the player's best stars.
class GameEngine {
  const GameEngine();

  PlayerProgress freshProgress() => PlayerProgress.initial();

  GameOutcome startJourney(PlayerProgress p, DateTime now) {
    if (p.onboardingDone) return GameOutcome.unchanged(p);
    final c = _Change(p, now);
    c.onboarding = true;
    c.event(
      RestorationEventType.arrival,
      'Field book opened',
      'Greater Tunis lies below you. The Medina is the first place to investigate.',
      siteId: SiteIds.medina,
      significant: true,
    );
    return _finish(c);
  }

  // ------------------------------------------------------------- sorting

  SortOutcome sortItem(
    PlayerProgress p,
    WasteItem item,
    WasteCategory chosen, {
    required int previousWrong,
    required DateTime now,
  }) {
    final correct = item.category == chosen;
    final level = Progression.levelFor(p.xp);
    if (!correct) {
      return SortOutcome(
        item: item,
        chosen: chosen,
        correct: false,
        wrongCount: previousWrong + 1,
        newlyMastered: false,
        outcome: GameOutcome(progress: p.copyWith(totalWrong: p.totalWrong + 1), levelBefore: level, levelAfter: level),
      );
    }
    final c = _Change(p, now);
    c.totalCorrect += 1;
    final newlyMastered = !c.mastered.contains(item.id);
    if (newlyMastered) {
      final wasFirst = c.mastered.isEmpty;
      c.mastered.add(item.id);
      if (previousWrong == 0) c.firstTry.add(item.id);
      c.addXp(previousWrong == 0 ? GameRules.xpFirstTry : GameRules.xpAfterRetry);
      if (wasFirst) {
        c.event(RestorationEventType.firstSort, 'First item sorted: ${item.name}',
            'Into "${item.category.label}". ${item.explanation}',
            siteId: SiteIds.medina);
      }
      // Field Training completes automatically at 5 learned items.
      final training = missionById(MissionIds.fieldTraining)!;
      if (c.mastered.length >= GameRules.fieldTrainingItems && !c.p0.isMissionDone(training.id)) {
        _award(c, training, 3, 'You learned ${c.mastered.length} sorting items.');
      }
    }
    return SortOutcome(
      item: item,
      chosen: chosen,
      correct: true,
      wrongCount: previousWrong,
      newlyMastered: newlyMastered,
      outcome: _finish(c),
    );
  }

  // ------------------------------------------------------------- missions

  MissionState stateOf(PlayerProgress p, String missionId) {
    final m = missionById(missionId);
    return m == null ? MissionState.locked : WorldRules.stateOf(p, m);
  }

  /// Trace (digitize): scored by geodesic AREA of the ring.
  MissionResult completeTrace(PlayerProgress p, String missionId, List<LatLng> ring, DateTime now) {
    final m = _mission(missionId, MissionType.digitize);
    final area = Geodesy.polygonArea(ring);
    final stars = ring.length < 3 ? 0 : Geodesy.stars(area, m.referenceValue);
    final summary = 'Your polygon: ${Geodesy.formatArea(area)} (perimeter ${Geodesy.formatDistance(Geodesy.perimeter(ring))}). '
        'Reference: ${m.referenceLabel} — ${m.referenceSource} (${m.referenceKind.label.toLowerCase()}).';
    return _score(p, m, stars, summary, now);
  }

  /// Measure: scored by great-circle DISTANCE between two points.
  MissionResult completeMeasure(PlayerProgress p, String missionId, LatLng a, LatLng b, DateTime now) {
    final m = _mission(missionId, MissionType.measure);
    final measured = Geodesy.distance(a, b);
    final reference = referenceDistance(m);
    final stars = Geodesy.stars(measured, reference);
    final summary = 'You measured ${Geodesy.formatDistance(measured)} in a straight line. '
        'Reference (${m.referenceLabel}): ${Geodesy.formatDistance(reference)} — ${m.referenceSource} (approximate).';
    return _score(p, m, stars, summary, now);
  }

  /// The measure mission's reference: Zaytuna Mosque → Borj Chakir locality.
  double referenceDistance(Mission m) =>
      Geodesy.distance(siteById(SiteIds.medina).center, siteById(SiteIds.borjChakir).center);

  /// Time Machine: the pins become personal annotations; 3 pins → 3★.
  MissionResult completeTimeMachine(PlayerProgress p, String missionId, List<LatLng> pins, DateTime now) {
    final m = _mission(missionId, MissionType.timeMachine);
    final enough = pins.length >= m.markersNeeded;
    final stars = enough ? 3 : 0;
    final summary = 'You pinned ${pins.length} change observations between the 2016 and 2024 mosaics. '
        'They are your interpretation, not verified facts.';
    return _score(p, m, stars, summary, now, extra: (c) {
      if (!enough) return;
      for (var i = 0; i < pins.length; i++) {
        c.annotations.add(MapAnnotation(
          id: 'a${now.millisecondsSinceEpoch}_$i',
          lat: pins[i].latitude,
          lon: pins[i].longitude,
          missionId: m.id,
          note: 'Possible change 2016 → 2024 (my observation)',
          timestamp: now,
        ));
      }
    });
  }

  /// Quiz: answers are option indexes, one per question.
  MissionResult completeQuiz(PlayerProgress p, String missionId, List<int> answers, DateTime now) {
    final m = _mission(missionId, MissionType.quiz);
    var correct = 0;
    for (var i = 0; i < m.quiz.length && i < answers.length; i++) {
      final a = answers[i];
      if (a >= 0 && a < m.quiz[i].options.length && m.quiz[i].options[a].correct) correct++;
    }
    final stars = WorldRules.quizStars(correct, m.quiz.length);
    return _score(p, m, stars, '$correct of ${m.quiz.length} answers correct.', now);
  }

  /// Land cover: one answer per example.
  MissionResult completeLandCover(PlayerProgress p, String missionId, List<LandCoverClass> answers, DateTime now) {
    final m = _mission(missionId, MissionType.landCover);
    var correct = 0;
    for (var i = 0; i < m.landCover.length && i < answers.length; i++) {
      if (m.landCover[i].answer == answers[i]) correct++;
    }
    final stars = correct > 3 ? 3 : correct;
    return _score(p, m, stars, '$correct of ${m.landCover.length} views read correctly.', now);
  }

  // ------------------------------------------------------- field evidence

  /// Saves a field-evidence record. Completes the Field Evidence mission when
  /// the record is linked to it and the mission is available.
  GameOutcome addFieldRecord(PlayerProgress p, LabeledPhoto record, DateTime now) {
    if (p.fieldRecords.any((r) => r.id == record.id)) return GameOutcome.unchanged(p);
    final c = _Change(p, now);
    c.records.add(record);
    if (c.records.length <= GameRules.recordXpCap) c.addXp(GameRules.xpPerRecord);
    c.event(
      RestorationEventType.evidence,
      'Field evidence saved',
      'Manual label: ${WasteCategory.fromId(record.categoryId)?.label ?? record.categoryId}. ${record.location.label}.',
      siteId: record.missionId == null ? null : missionById(record.missionId!)?.siteId,
    );
    final m = missionById(MissionIds.fieldEvidence)!;
    if (record.missionId == m.id && WorldRules.stateOf(p, m) == MissionState.available) {
      _award(c, m, 3, 'You saved your first field-evidence record.');
    }
    return _finish(c);
  }

  GameOutcome removeFieldRecord(PlayerProgress p, String id, DateTime now) {
    if (!p.fieldRecords.any((r) => r.id == id)) return GameOutcome.unchanged(p);
    final c = _Change(p, now);
    c.records.removeWhere((r) => r.id == id);
    return _finish(c);
  }

  GameOutcome removeAnnotation(PlayerProgress p, String id, DateTime now) {
    if (!p.annotations.any((a) => a.id == id)) return GameOutcome.unchanged(p);
    final c = _Change(p, now);
    c.annotations.removeWhere((a) => a.id == id);
    return _finish(c);
  }

  // ------------------------------------------------------------- internal

  Mission _mission(String id, MissionType type) {
    final m = missionById(id);
    if (m == null || m.type != type) throw ArgumentError('No $type mission "$id"');
    return m;
  }

  MissionResult _score(PlayerProgress p, Mission m, int stars, String summary, DateTime now,
      {void Function(_Change c)? extra}) {
    final state = WorldRules.stateOf(p, m);
    if (state == MissionState.locked) {
      return MissionResult(mission: m, stars: stars, summary: summary, outcome: GameOutcome.unchanged(p, 'This mission is still locked.'));
    }
    if (stars <= p.starsOf(m.id)) {
      return MissionResult(
        mission: m,
        stars: stars,
        summary: summary,
        outcome: GameOutcome.unchanged(
            p, stars == 0 ? 'No stars this time — try again.' : 'Saved best: ${p.starsOf(m.id)}★. No new XP.'),
      );
    }
    final c = _Change(p, now);
    extra?.call(c);
    _award(c, m, stars, summary);
    return MissionResult(mission: m, stars: stars, summary: summary, outcome: _finish(c));
  }

  /// Grants XP for the improvement only, logs the mission and any reveals.
  void _award(_Change c, Mission m, int stars, String summary) {
    final previous = c.stars[m.id] ?? 0;
    if (stars <= previous) return;
    final revealedBefore = WorldRules.revealedSites(c.snapshot());
    c.stars[m.id] = stars;
    c.addXp((stars - previous) * m.xpPerStar);
    c.event(
      RestorationEventType.mission,
      '${m.title} — ${'★' * stars}${'☆' * (3 - stars)}',
      '$summary ${m.learning}',
      siteId: m.siteId,
      significant: previous == 0,
    );
    final revealedAfter = WorldRules.revealedSites(c.snapshot());
    for (final id in revealedAfter.difference(revealedBefore)) {
      final s = siteById(id);
      c.revealed.add(id);
      c.event(RestorationEventType.reveal, 'New place revealed: ${s.name}',
          'Unlocked because you completed "${m.title}". ${s.whyItMatters}',
          siteId: id, significant: true);
    }
  }

  GameOutcome _finish(_Change c) {
    var snapshot = c.snapshot();
    var earned = AchievementRules.newlyEarned(snapshot);
    while (earned.isNotEmpty) {
      for (final id in earned) {
        c.achievements[id] = c.now.millisecondsSinceEpoch;
        c.newAchievements.add(id);
        final a = achievementById(id);
        c.event(RestorationEventType.achievement, 'Achievement: ${a?.title ?? id}', a?.description ?? '');
      }
      snapshot = c.snapshot();
      earned = AchievementRules.newlyEarned(snapshot);
    }
    final before = Progression.levelFor(c.p0.xp);
    final after = Progression.levelFor(c.xp);
    if (after > before) {
      c.event(RestorationEventType.levelUp, 'Level $after: ${Progression.titleFor(after)}',
          'Reached ${GameRules.levelThresholds[after - 1]} XP (game score).');
      snapshot = c.snapshot();
    }
    return GameOutcome(
      progress: snapshot,
      levelBefore: before,
      levelAfter: after,
      xpGained: c.xpGained,
      newAchievements: List.unmodifiable(c.newAchievements),
      revealedSites: List.unmodifiable(c.revealed),
    );
  }
}

/// Mutable working copy used while applying one action.
class _Change {
  _Change(this.p0, this.now)
      : onboarding = p0.onboardingDone,
        xp = p0.xp,
        mastered = {...p0.masteredItems},
        firstTry = {...p0.firstTryItems},
        totalCorrect = p0.totalCorrect,
        totalWrong = p0.totalWrong,
        stars = {...p0.missionStars},
        achievements = {...p0.achievements},
        events = [...p0.events],
        seq = p0.nextSeq,
        annotations = [...p0.annotations],
        records = [...p0.fieldRecords];

  final PlayerProgress p0;
  final DateTime now;
  bool onboarding;
  int xp;
  final Set<String> mastered;
  final Set<String> firstTry;
  int totalCorrect;
  int totalWrong;
  final Map<String, int> stars;
  final Map<String, int> achievements;
  final List<RestorationEvent> events;
  int seq;
  final List<MapAnnotation> annotations;
  final List<LabeledPhoto> records;

  int xpGained = 0;
  final List<String> newAchievements = [];
  final List<String> revealed = [];

  void addXp(int v) {
    xp += v;
    xpGained += v;
  }

  void event(RestorationEventType type, String title, String note, {String? siteId, bool significant = false}) {
    events.add(RestorationEvent(
      seq: seq++,
      type: type,
      title: title,
      note: note,
      timestamp: now,
      zoneId: siteId,
      significant: significant,
    ));
  }

  PlayerProgress snapshot() => PlayerProgress(
        onboardingDone: onboarding,
        xp: xp,
        masteredItems: Set.unmodifiable(mastered),
        firstTryItems: Set.unmodifiable(firstTry),
        totalCorrect: totalCorrect,
        totalWrong: totalWrong,
        missionStars: Map.unmodifiable(stars),
        achievements: Map.unmodifiable(achievements),
        events: List.unmodifiable(events),
        nextSeq: seq,
        annotations: List.unmodifiable(annotations),
        fieldRecords: List.unmodifiable(records),
      );
}
