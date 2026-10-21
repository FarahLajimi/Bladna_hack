import 'labeled_photo.dart';
import 'map_annotation.dart';
import 'restoration_event.dart';

/// The complete saved game state (schema 2). Immutable: the GameEngine
/// returns a new instance for every change, which keeps rules testable.
class PlayerProgress {
  const PlayerProgress({
    required this.onboardingDone,
    required this.xp,
    required this.masteredItems,
    required this.firstTryItems,
    required this.totalCorrect,
    required this.totalWrong,
    required this.missionStars,
    required this.achievements,
    required this.events,
    required this.nextSeq,
    required this.annotations,
    required this.fieldRecords,
  });

  static const int schemaVersion = 2;

  /// True once the player has entered the map for the first time.
  final bool onboardingDone;
  final int xp;

  /// Waste items sorted correctly at least once (XP is granted once each).
  final Set<String> masteredItems;
  final Set<String> firstTryItems;
  final int totalCorrect;
  final int totalWrong;

  /// missionId -> best stars (1..3). A mission is "completed" when present.
  final Map<String, int> missionStars;

  /// achievementId -> unlock time (ms since epoch).
  final Map<String, int> achievements;
  final List<RestorationEvent> events;
  final int nextSeq;

  /// Personal map annotations (user-placed positions).
  final List<MapAnnotation> annotations;

  /// Field-evidence photos with manual labels.
  final List<LabeledPhoto> fieldRecords;

  factory PlayerProgress.initial() => const PlayerProgress(
        onboardingDone: false,
        xp: 0,
        masteredItems: {},
        firstTryItems: {},
        totalCorrect: 0,
        totalWrong: 0,
        missionStars: {},
        achievements: {},
        events: [],
        nextSeq: 1,
        annotations: [],
        fieldRecords: [],
      );

  bool isMissionDone(String id) => (missionStars[id] ?? 0) > 0;
  int starsOf(String id) => missionStars[id] ?? 0;

  PlayerProgress copyWith({
    bool? onboardingDone,
    int? xp,
    Set<String>? masteredItems,
    Set<String>? firstTryItems,
    int? totalCorrect,
    int? totalWrong,
    Map<String, int>? missionStars,
    Map<String, int>? achievements,
    List<RestorationEvent>? events,
    int? nextSeq,
    List<MapAnnotation>? annotations,
    List<LabeledPhoto>? fieldRecords,
  }) {
    return PlayerProgress(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      xp: xp ?? this.xp,
      masteredItems: masteredItems ?? this.masteredItems,
      firstTryItems: firstTryItems ?? this.firstTryItems,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalWrong: totalWrong ?? this.totalWrong,
      missionStars: missionStars ?? this.missionStars,
      achievements: achievements ?? this.achievements,
      events: events ?? this.events,
      nextSeq: nextSeq ?? this.nextSeq,
      annotations: annotations ?? this.annotations,
      fieldRecords: fieldRecords ?? this.fieldRecords,
    );
  }

  Map<String, dynamic> toJson() => {
        'v': schemaVersion,
        'onboardingDone': onboardingDone,
        'xp': xp,
        'mastered': masteredItems.toList(),
        'firstTry': firstTryItems.toList(),
        'totalCorrect': totalCorrect,
        'totalWrong': totalWrong,
        'missionStars': missionStars,
        'achievements': achievements,
        'events': events.map((e) => e.toJson()).toList(),
        'nextSeq': nextSeq,
        'annotations': annotations.map((a) => a.toJson()).toList(),
        'records': fieldRecords.map((p) => p.toJson()).toList(),
      };

  /// Defensive decoding. Understands schema 2 and the older schema 1 (the
  /// Butterfly Block prototype): XP, learned items, achievements, journal
  /// events, Sky Lab stars and labeled photos are carried over.
  static PlayerProgress fromJson(Map<String, dynamic> json) {
    final fallback = PlayerProgress.initial();
    Set<String> strings(Object? raw) => raw is List ? Set.unmodifiable(raw.whereType<String>()) : const {};
    int integer(Object? raw, int def) => raw is int ? raw : def;

    Map<String, int> intMap(Object? raw) {
      if (raw is! Map) return const {};
      final out = <String, int>{};
      raw.forEach((k, v) {
        if (k is String && v is int) out[k] = v;
      });
      return Map.unmodifiable(out);
    }

    List<T> list<T>(Object? raw, T? Function(Object?) parse) {
      if (raw is! List) return const [];
      final out = <T>[];
      for (final r in raw) {
        final p = parse(r);
        if (p != null) out.add(p);
      }
      return List.unmodifiable(out);
    }

    final events = [...list(json['events'], RestorationEvent.tryFromJson)]..sort((a, b) => a.seq.compareTo(b.seq));
    final maxSeq = events.isEmpty ? 0 : events.last.seq;
    // Schema 1 stored Sky Lab stars under 'skyQuestStars' and photos under 'photos'.
    final stars = json.containsKey('missionStars') ? intMap(json['missionStars']) : intMap(json['skyQuestStars']);
    final records = list(json.containsKey('records') ? json['records'] : json['photos'], LabeledPhoto.tryFromJson);
    final next = integer(json['nextSeq'], 1);

    return PlayerProgress(
      onboardingDone: json['onboardingDone'] == true,
      xp: integer(json['xp'], fallback.xp),
      masteredItems: strings(json['mastered']),
      firstTryItems: strings(json['firstTry']),
      totalCorrect: integer(json['totalCorrect'], 0),
      totalWrong: integer(json['totalWrong'], 0),
      missionStars: stars,
      achievements: intMap(json['achievements']),
      events: List.unmodifiable(events),
      nextSeq: next > maxSeq ? next : maxSeq + 1,
      annotations: list(json['annotations'], MapAnnotation.tryFromJson),
      fieldRecords: records,
    );
  }
}
