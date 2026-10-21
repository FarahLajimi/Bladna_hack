import 'dart:convert';

import 'package:bladna/data/local_data/world_data.dart';
import 'package:bladna/data/models/app_settings.dart';
import 'package:bladna/data/models/labeled_photo.dart';
import 'package:bladna/data/repositories/progress_repository.dart';
import 'package:bladna/services/auth/auth_service.dart';
import 'package:bladna/state/game_controller.dart';
import 'package:bladna/state/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('progress survives save and reload', () async {
    final prefs = await SharedPreferences.getInstance();
    var p = learn(startedPlayer(), 5);
    p = engine
        .addFieldRecord(
            p, LabeledPhoto(id: 'r1', path: '/x.jpg', categoryId: 'glass', timestamp: now, note: 'jar'), now)
        .progress;
    await ProgressRepository(prefs).saveProgress(p);
    final r = ProgressRepository(prefs).loadProgress();
    expect(r.xp, p.xp);
    expect(r.masteredItems, p.masteredItems);
    expect(r.missionStars, p.missionStars);
    expect(r.achievements, p.achievements);
    expect(r.events.map((e) => e.title).toList(), p.events.map((e) => e.title).toList());
    expect(r.fieldRecords.single.note, 'jar');
    expect(r.fieldRecords.single.location, RecordLocation.none);
    // Rewards cannot be re-claimed after a reload.
    expect(learn(r, 0).xp, r.xp);
  });

  test('a schema-1 save (earlier prototype) is migrated', () async {
    SharedPreferences.setMockInitialValues({
      ProgressRepository.progressKey: jsonEncode({
        'v': 1,
        'onboardingDone': true,
        'xp': 120,
        'mastered': ['plastic_bottle', 'battery', 'not_an_item'],
        'achievements': {'first_steps': 1, 'butterfly_effect': 2},
        'skyQuestStars': {'trace_lake': 2, 'old_quest': 3},
        'photos': [
          {'id': 'p1', 'path': '/a.jpg', 'cat': 'packaging', 'ts': 0},
        ],
        'events': [
          {'seq': 1, 'type': 'arrival', 'title': 'Hi', 'note': '', 'ts': 0},
          {'seq': 2, 'type': 'ripple', 'title': 'Old type', 'note': '', 'ts': 0},
        ],
        'zonePoints': {'street': 40},
      }),
    });
    final p = ProgressRepository(await SharedPreferences.getInstance()).loadProgress();
    expect(p.xp, 120);
    expect(p.masteredItems, {'plastic_bottle', 'battery'});
    expect(p.achievements.keys, ['first_steps']);
    expect(p.missionStars, {MissionIds.traceLake: 2});
    expect(p.fieldRecords.single.id, 'p1');
    expect(p.events.length, 1, reason: 'unknown event types are skipped');
    expect(p.nextSeq, 2, reason: "continues after the last kept event");
  });

  test('corrupt or future saves never crash', () async {
    SharedPreferences.setMockInitialValues({ProgressRepository.progressKey: '{oops'});
    var prefs = await SharedPreferences.getInstance();
    expect(ProgressRepository(prefs).loadProgress().xp, 0);
    expect(prefs.getString(ProgressRepository.unreadableBackupKey), '{oops');

    SharedPreferences.setMockInitialValues({ProgressRepository.progressKey: jsonEncode({'v': 99, 'xp': 9})});
    prefs = await SharedPreferences.getInstance();
    expect(ProgressRepository(prefs).loadProgress().xp, 0);
  });

  test('reset erases progress but keeps settings and the session', () async {
    final prefs = await SharedPreferences.getInstance();
    final session = SessionController(prefs: prefs);
    await session.continueAsGuest('Farah');
    final game = GameController(repository: ProgressRepository(prefs), clock: () => now);
    game.startJourney();
    game.updateSettings(const AppSettings(haptics: false, reduceMotion: true));
    await game.saved;
    await game.resetProgress();
    expect(game.progress.onboardingDone, isFalse);
    expect(game.settings.reduceMotion, isTrue);
    expect(SessionController(prefs: prefs).isGuest, isTrue);
  });

  group('Session', () {
    test('guest session persists; sign-out keeps local progress', () async {
      final prefs = await SharedPreferences.getInstance();
      final s = SessionController(prefs: prefs);
      expect(s.isSignedIn, isFalse);
      await s.continueAsGuest('  Nour ');
      expect(SessionController(prefs: prefs).displayName, 'Nour');

      final repo = ProgressRepository(prefs);
      await repo.saveProgress(learn(startedPlayer(), 2));
      await s.signOut();
      expect(s.isSignedIn, isFalse);
      expect(SessionController(prefs: prefs).isSignedIn, isFalse);
      expect(repo.loadProgress().masteredItems.length, 2);
    });

    test('without a provider, account calls fail honestly and store nothing', () async {
      final prefs = await SharedPreferences.getInstance();
      final s = SessionController(prefs: prefs);
      expect(s.auth.isConfigured, isFalse);
      await expectLater(s.signIn('a@b.tn', 'secret123'), throwsA(isA<AuthNotConfigured>()));
      await expectLater(s.createAccount('A', 'a@b.tn', 'secret123'), throwsA(isA<AuthNotConfigured>()));
      expect(s.isSignedIn, isFalse);
      for (final k in prefs.getKeys()) {
        expect(prefs.get(k).toString(), isNot(contains('secret123')), reason: 'passwords are never stored');
      }
    });

    test('form validators', () {
      expect(AuthValidators.email('nope'), isNotNull);
      expect(AuthValidators.email('a@b.tn'), isNull);
      expect(AuthValidators.password('short'), isNotNull);
      expect(AuthValidators.password('longenough'), isNull);
    });
  });
}
