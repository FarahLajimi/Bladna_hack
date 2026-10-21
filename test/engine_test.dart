import 'dart:math' as math;

import 'package:bladna/core/constants/game_rules.dart';
import 'package:bladna/data/local_data/achievements_data.dart';
import 'package:bladna/data/local_data/waste_items_data.dart';
import 'package:bladna/data/local_data/world_data.dart';
import 'package:bladna/data/models/labeled_photo.dart';
import 'package:bladna/data/models/restoration_event.dart';
import 'package:bladna/data/models/waste_category.dart';
import 'package:bladna/data/models/world.dart';
import 'package:bladna/domain/progression.dart';
import 'package:bladna/domain/world_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'test_helpers.dart';

LabeledPhoto record(int i, {String? mission}) => LabeledPhoto(
      id: 'r$i',
      path: '/tmp/r$i.jpg',
      categoryId: 'packaging',
      timestamp: now,
      missionId: mission,
      location: mission == null ? RecordLocation.none : RecordLocation.missionLink,
    );

void main() {
  final bottle = wasteItemById('plastic_bottle')!;
  final medina = siteById(SiteIds.medina).center;
  final borj = siteById(SiteIds.borjChakir).center;

  group('Start of the journey', () {
    test('only the Medina is revealed and Field Training is available', () {
      final p = startedPlayer();
      expect(WorldRules.revealedSites(p), {SiteIds.medina});
      expect(WorldRules.stateOf(p, missionById(MissionIds.fieldTraining)!), MissionState.available);
      expect(WorldRules.stateOf(p, missionById(MissionIds.wasteRoute)!), MissionState.locked);
      expect(p.events.single.type, RestorationEventType.arrival);
      expect(engine.startJourney(p, now).applied, isFalse);
    });
  });

  group('Sorting (Field Training)', () {
    test('first-try sort: 10 XP once; retry: 5 XP; repeat: 0 XP', () {
      final p = startedPlayer();
      final hit = engine.sortItem(p, bottle, WasteCategory.packaging, previousWrong: 0, now: now);
      expect(hit.outcome.xpGained, GameRules.xpFirstTry);
      final again = engine.sortItem(hit.outcome.progress, bottle, WasteCategory.packaging, previousWrong: 0, now: now);
      expect(again.outcome.xpGained, 0);
      expect(again.newlyMastered, isFalse);

      final miss = engine.sortItem(p, bottle, WasteCategory.glass, previousWrong: 0, now: now);
      expect(miss.correct, isFalse);
      expect(miss.outcome.progress.xp, 0);
      expect(miss.showHint, isTrue);
      final retry = engine.sortItem(miss.outcome.progress, bottle, WasteCategory.packaging, previousWrong: 1, now: now);
      expect(retry.outcome.xpGained, GameRules.xpAfterRetry);
    });

    test('three misses reveal the answer without XP', () {
      var p = startedPlayer();
      var wrong = 0;
      for (final c in [WasteCategory.glass, WasteCategory.paper, WasteCategory.organic]) {
        final r = engine.sortItem(p, bottle, c, previousWrong: wrong, now: now);
        p = r.outcome.progress;
        wrong = r.wrongCount;
        if (wrong == 3) expect(r.revealAnswer, isTrue);
      }
      expect(p.xp, 0);
      expect(p.masteredItems, isEmpty);
    });

    test('learning 5 items completes Field Training once and reveals Borj Chakir', () {
      final p4 = learn(startedPlayer(), 4);
      expect(p4.isMissionDone(MissionIds.fieldTraining), isFalse);
      final p5 = learn(p4, 1);
      expect(p5.starsOf(MissionIds.fieldTraining), 3);
      expect(WorldRules.isRevealedId(p5, SiteIds.borjChakir), isTrue);
      expect(p5.events.any((e) => e.type == RestorationEventType.reveal && e.zoneId == SiteIds.borjChakir), isTrue);
      expect(p5.xp, 5 * GameRules.xpFirstTry + 3 * 15);
      final p6 = learn(p5, 1);
      expect(p6.xp, p5.xp + GameRules.xpFirstTry, reason: 'training reward is not granted twice');
    });
  });

  group('Map missions', () {
    test('locked missions give nothing', () {
      final r = engine.completeMeasure(startedPlayer(), MissionIds.wasteRoute, medina, borj, now);
      expect(r.outcome.applied, isFalse);
      expect(r.outcome.progress.xp, 0);
    });

    test('Where Does It Go? uses great-circle distance (3★ at the reference points)', () {
      final p = learn(startedPlayer(), 5);
      final r = engine.completeMeasure(p, MissionIds.wasteRoute, medina, borj, now);
      expect(r.stars, 3);
      expect(r.outcome.xpGained, 45);
      expect(r.summary, contains('km'));
      expect(WorldRules.isRevealedId(r.outcome.progress, SiteIds.sejoumi), isTrue);
    });

    test('a distance twice the reference earns no stars', () {
      final p = learn(startedPlayer(), 5);
      final far = west(borj, 9500);
      final r = engine.completeMeasure(p, MissionIds.wasteRoute, medina, far, now);
      expect(r.stars, 0);
      expect(r.outcome.applied, isFalse);
    });

    test('Trace scoring uses AREA and only improvements give XP', () {
      var p = learn(startedPlayer(), 5);
      p = engine.completeMeasure(p, MissionIds.wasteRoute, medina, borj, now).outcome.progress;
      final sej = siteById(SiteIds.sejoumi).center;
      // ≈ 2,979 ha → side ≈ 5,458 m.
      final good = engine.completeTrace(p, MissionIds.traceSejoumi, square(sej, math.sqrt(2979e4)), now);
      expect(good.stars, 3);
      expect(good.outcome.xpGained, 45);
      final again = engine.completeTrace(good.outcome.progress, MissionIds.traceSejoumi, square(sej, math.sqrt(2979e4)), now);
      expect(again.outcome.applied, isFalse);
      expect(again.outcome.progress.xp, good.outcome.progress.xp);

      final tiny = engine.completeTrace(p, MissionIds.traceSejoumi, square(sej, 1000), now);
      expect(tiny.stars, 0);
      expect(tiny.outcome.applied, isFalse);
    });

    test('Time Machine turns 3 pins into personal annotations', () {
      var p = learn(startedPlayer(), 5);
      p = engine.completeMeasure(p, MissionIds.wasteRoute, medina, borj, now).outcome.progress;
      final sej = siteById(SiteIds.sejoumi).center;
      final locked = engine.completeTimeMachine(p, MissionIds.shoreChange, [sej, sej, sej], now);
      expect(locked.outcome.applied, isFalse, reason: 'requires Evidence Before Conclusions');
      p = engine.completeQuiz(p, MissionIds.evidenceFirst, [1, 1, 1], now).outcome.progress;
      final r = engine.completeTimeMachine(p, MissionIds.shoreChange, [sej, sej, sej], now);
      expect(r.stars, 3);
      expect(r.outcome.progress.annotations.length, 3);
      final dup = engine.completeTimeMachine(r.outcome.progress, MissionIds.shoreChange, [sej, sej, sej], now);
      expect(dup.outcome.progress.annotations.length, 3, reason: 'no duplicate annotations or XP');
    });
  });

  group('Reasoning and land cover', () {
    test('quiz stars follow the stated rule', () {
      var p = learn(startedPlayer(), 5);
      expect(WorldRules.quizStars(4, 4), 3);
      expect(WorldRules.quizStars(3, 4), 2);
      expect(WorldRules.quizStars(2, 4), 1);
      expect(WorldRules.quizStars(1, 4), 0);
      expect(WorldRules.quizStars(2, 3), 2);
      final r = engine.completeQuiz(p, MissionIds.nameTheFacility, [0, 1, 2, 3], now);
      expect(r.stars, 3);
      p = r.outcome.progress;
      expect(WorldRules.stateOf(p, missionById(MissionIds.fieldEvidence)!), MissionState.available);
    });

    test('Evidence First achievement needs a perfect score', () {
      var p = learn(startedPlayer(), 5);
      p = engine.completeMeasure(p, MissionIds.wasteRoute, medina, borj, now).outcome.progress;
      final two = engine.completeQuiz(p, MissionIds.evidenceFirst, [0, 1, 1], now);
      expect(two.stars, 2);
      expect(two.outcome.newAchievements, isNot(contains(AchievementIds.evidenceFirst)));
      final three = engine.completeQuiz(two.outcome.progress, MissionIds.evidenceFirst, [1, 1, 1], now);
      expect(three.outcome.xpGained, 15, reason: 'only the extra star is paid');
      expect(three.outcome.newAchievements, contains(AchievementIds.evidenceFirst));
    });

    test('Read the Land scores one star per correct view', () {
      final m = missionById(MissionIds.readTheLand)!;
      var p = learn(startedPlayer(), 5);
      p = engine.completeMeasure(p, MissionIds.wasteRoute, medina, borj, now).outcome.progress;
      p = engine.completeQuiz(p, MissionIds.evidenceFirst, [1, 1, 1], now).outcome.progress;
      expect(WorldRules.isRevealedId(p, SiteIds.lake), isTrue);
      final answers = m.landCover.map((e) => e.answer).toList();
      expect(engine.completeLandCover(p, m.id, answers, now).stars, 3);
      final oneWrong = [...answers]..[0] = LandCoverClass.vegetation;
      expect(engine.completeLandCover(p, m.id, oneWrong, now).stars, 2);
    });
  });

  group('Field evidence', () {
    test('a linked record completes the mission; unlinked ones do not', () {
      var p = learn(startedPlayer(), 5);
      p = engine.completeQuiz(p, MissionIds.nameTheFacility, [0, 1, 2, 3], now).outcome.progress;
      final loose = engine.addFieldRecord(p, record(1), now);
      expect(loose.progress.isMissionDone(MissionIds.fieldEvidence), isFalse);
      final linked = engine.addFieldRecord(loose.progress, record(2, mission: MissionIds.fieldEvidence), now);
      expect(linked.progress.starsOf(MissionIds.fieldEvidence), 3);
      expect(linked.progress.fieldRecords.length, 2);
      final removed = engine.removeFieldRecord(linked.progress, 'r1', now);
      expect(removed.progress.fieldRecords.single.id, 'r2');
    });

    test('record XP is capped and Data Gardener unlocks at 5', () {
      var p = startedPlayer();
      for (var i = 0; i < 12; i++) {
        p = engine.addFieldRecord(p, record(i), now).progress;
      }
      expect(p.xp, GameRules.recordXpCap * GameRules.xpPerRecord);
      expect(p.achievements.keys, contains(AchievementIds.dataGardener));
      expect(engine.addFieldRecord(p, record(3), now).applied, isFalse);
    });
  });

  group('Full exploration', () {
    test('completing every mission reveals every place and unlocks Young Geomatician', () {
      var p = learn(startedPlayer(), 5);
      p = engine.completeMeasure(p, MissionIds.wasteRoute, medina, borj, now).outcome.progress;
      p = engine.completeQuiz(p, MissionIds.nameTheFacility, [0, 1, 2, 3], now).outcome.progress;
      p = engine.addFieldRecord(p, record(1, mission: MissionIds.fieldEvidence), now).progress;
      final sej = siteById(SiteIds.sejoumi).center;
      p = engine.completeTrace(p, MissionIds.traceSejoumi, square(sej, math.sqrt(2979e4)), now).outcome.progress;
      p = engine.completeQuiz(p, MissionIds.evidenceFirst, [1, 1, 1], now).outcome.progress;
      p = engine.completeTimeMachine(p, MissionIds.shoreChange, [sej, sej, sej], now).outcome.progress;
      final lake = siteById(SiteIds.lake).center;
      p = engine.completeTrace(p, MissionIds.traceLake, square(lake, math.sqrt(37e6)), now).outcome.progress;
      final lc = missionById(MissionIds.readTheLand)!.landCover.map((e) => e.answer).toList();
      p = engine.completeLandCover(p, MissionIds.readTheLand, lc, now).outcome.progress;

      expect(kMissions.every((m) => p.isMissionDone(m.id)), isTrue);
      expect(WorldRules.revealedSites(p), SiteIds.all.toSet());
      expect(WorldRules.nextMission(p), isNull);
      for (final id in [
        AchievementIds.fieldReady,
        AchievementIds.eyeInTheSky,
        AchievementIds.wetlandReader,
        AchievementIds.cartographer,
        AchievementIds.geomatician,
      ]) {
        expect(p.achievements.keys, contains(id), reason: id);
      }
      final missionXp = kMissions.fold<int>(0, (s, m) => s + 3 * m.xpPerStar);
      expect(p.xp, 5 * GameRules.xpFirstTry + missionXp + GameRules.xpPerRecord);
      expect(Progression.levelFor(p.xp), greaterThanOrEqualTo(3));
    });
  });
}

/// [p] moved [meters] to the west.
LatLng west(LatLng p, double meters) =>
    LatLng(p.latitude, p.longitude - meters / (111195.0 * math.cos(p.latitude * math.pi / 180)));
