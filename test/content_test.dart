import 'package:bladna/data/local_data/achievements_data.dart';
import 'package:bladna/data/local_data/waste_items_data.dart';
import 'package:bladna/data/local_data/world_data.dart';
import 'package:bladna/data/models/waste_category.dart';
import 'package:bladna/data/models/world.dart';
import 'package:bladna/domain/achievement_rules.dart';
import 'package:bladna/domain/sort_round_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('World content', () {
    test('places are real, inside Greater Tunis and every fact has a source', () {
      expect(kSites.map((s) => s.id).toSet().length, kSites.length);
      for (final s in kSites) {
        expect(s.center.latitude, inInclusiveRange(36.6, 37.0), reason: s.id);
        expect(s.center.longitude, inInclusiveRange(9.9, 10.4), reason: s.id);
        expect(s.evidence, isNotEmpty, reason: s.id);
        for (final e in s.evidence) {
          expect(e.source.trim(), isNotEmpty, reason: s.id);
        }
        if (s.approximate) {
          expect(s.approxRadiusMeters, greaterThan(0));
          expect(s.evidence.any((e) => e.confidence == Confidence.approximate), isTrue,
              reason: 'approximate places must say so');
        }
        expect(s.lookingAt, isNotEmpty);
        expect(s.whyItMatters, isNotEmpty);
      }
      expect(siteById(SiteIds.borjChakir).approximate, isTrue);
    });

    test('missions reference valid places and missions; content is complete', () {
      final ids = kMissions.map((m) => m.id).toSet();
      expect(ids.length, kMissions.length);
      for (final m in kMissions) {
        expect(SiteIds.all, contains(m.siteId));
        for (final r in m.requires) {
          expect(ids, contains(r));
        }
        expect(m.question, isNotEmpty);
        expect(m.task, isNotEmpty);
        expect(m.learning, isNotEmpty);
        expect(m.rule, isNotEmpty);
        if (m.type == MissionType.digitize) {
          expect(m.referenceValue, greaterThan(0), reason: m.id);
          expect(m.referenceSource, isNotEmpty, reason: m.id);
        }
        if (m.type == MissionType.measure) expect(m.referenceSource, isNotEmpty);
        if (m.type == MissionType.quiz) {
          expect(m.quiz, isNotEmpty, reason: m.id);
          for (final q in m.quiz) {
            expect(q.options.where((o) => o.correct).length, 1, reason: q.prompt);
          }
        }
        if (m.type == MissionType.landCover) expect(m.landCover, isNotEmpty);
      }
      for (final s in kSites) {
        for (final r in s.revealedBy) {
          expect(ids, contains(r), reason: s.id);
        }
      }
    });

    test('exactly one start place, and every place is reachable', () {
      expect(kSites.where((s) => s.revealedBy.isEmpty).length, 1);
      final revealed = kSites.where((s) => s.revealedBy.isEmpty).map((s) => s.id).toSet();
      final done = <String>{};
      var changed = true;
      while (changed) {
        changed = false;
        for (final m in kMissions) {
          if (!done.contains(m.id) && revealed.contains(m.siteId) && m.requires.every(done.contains)) {
            done.add(m.id);
            changed = true;
          }
        }
        for (final s in kSites) {
          if (!revealed.contains(s.id) && s.revealedBy.any(done.contains)) {
            revealed.add(s.id);
            changed = true;
          }
        }
      }
      expect(revealed, SiteIds.all.toSet());
      expect(done, kMissions.map((m) => m.id).toSet());
    });

    test('imagery layers use HTTPS and carry attribution', () {
      for (final b in kBasemaps) {
        expect(b.urlTemplate, startsWith('https://'));
        expect(b.attribution, isNotEmpty);
        expect(b.detail, isNotEmpty);
      }
    });
  });

  group('Sorting content', () {
    test('at least 20 distinct items; every category represented; hazards guided', () {
      expect(kWasteItems.length, greaterThanOrEqualTo(20));
      expect(kWasteItems.map((i) => i.id).toSet().length, kWasteItems.length);
      for (final c in WasteCategory.values) {
        expect(kWasteItems.where((i) => i.category == c).length, greaterThanOrEqualTo(2), reason: c.id);
      }
      for (final i in kWasteItems.where((i) => i.category == WasteCategory.special)) {
        expect(i.dependsOnLocalRules || i.safetyNote != null, isTrue, reason: i.id);
      }
    });

    test('round planner serves unlearned items first', () {
      final p = learn(startedPlayer(), 6);
      final round = SortRoundPlanner.plan(p);
      expect(round.length, 6);
      expect(round.any((i) => p.masteredItems.contains(i.id)), isFalse);
    });
  });

  test('every achievement has a rule', () {
    for (final a in kAchievements) {
      expect(AchievementRules.conditions.containsKey(a.id), isTrue, reason: a.id);
    }
  });
}
