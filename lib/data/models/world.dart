import 'package:latlong2/latlong.dart';

/// How much a piece of evidence can be trusted. Shown on every fact.
enum Confidence {
  official('Official figure'),
  reported('Reported'),
  documented('Documented'),
  approximate('Approximate location'),
  educational('Educational example');

  const Confidence(this.label);
  final String label;
}

class Evidence {
  const Evidence(this.text, this.source, this.confidence);
  final String text;

  /// Short source label; full links in README.md → "Data sources".
  final String source;
  final Confidence confidence;
}

/// A REAL place in Greater Tunis that the player can investigate.
class RealSite {
  const RealSite({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.center,
    required this.kind,
    required this.lookingAt,
    required this.whyItMatters,
    required this.evidence,
    required this.focusZoom,
    this.revealedBy = const [],
    this.revealHint = '',
    this.approximate = false,
    this.approxRadiusMeters = 0,
  });

  final String id;
  final String name;
  final String arabicName;
  final LatLng center;
  final String kind;

  /// "What you're looking at" — plain description of the imagery.
  final String lookingAt;

  /// Ecological / waste-management reason the place matters.
  final String whyItMatters;
  final List<Evidence> evidence;
  final double focusZoom;

  /// Mission ids — completing ANY of them reveals this site. Empty = start site.
  final List<String> revealedBy;
  final String revealHint;

  /// True when [center] is a locality coordinate, not a surveyed point.
  final bool approximate;
  final double approxRadiusMeters;
}

enum MissionType {
  /// The waste-sorting mini-game (Field Training).
  sorting('Field training'),

  /// Trace a polygon on the map; scored by geodesic AREA.
  digitize('Trace'),

  /// Tap two points; scored by great-circle DISTANCE.
  measure('Measure'),

  /// Compare two imagery dates and record observations.
  timeMachine('Compare dates'),

  /// Classify land cover at documented example points.
  landCover('Read the land'),

  /// Multiple-choice reasoning questions.
  quiz('Reasoning'),

  /// Photograph and label real waste (computer-vision data collection).
  fieldEvidence('Field evidence');

  const MissionType(this.label);
  final String label;

  /// Missions played directly on the explore map (not a separate screen).
  bool get onMap => this == digitize || this == measure || this == timeMachine;
}

class QuizOption {
  const QuizOption(this.text, {this.correct = false});
  final String text;
  final bool correct;
}

class QuizQuestion {
  const QuizQuestion({required this.prompt, required this.options, required this.explanation});
  final String prompt;
  final List<QuizOption> options;
  final String explanation;
}

class LandCoverExample {
  const LandCoverExample({
    required this.point,
    required this.answer,
    required this.explanation,
    required this.source,
  });
  final LatLng point;
  final LandCoverClass answer;
  final String explanation;
  final String source;
}

enum LandCoverClass {
  water('Water'),
  vegetation('Vegetation'),
  builtUp('Built-up'),
  bareSoil('Bare soil'),
  wetland('Wetland');

  const LandCoverClass(this.label);
  final String label;
}

/// One mission: a place, a question, evidence, a task, a learning point and
/// a transparent completion rule.
class Mission {
  const Mission({
    required this.id,
    required this.siteId,
    required this.title,
    required this.question,
    required this.task,
    required this.learning,
    required this.rule,
    required this.type,
    this.xpPerStar = 15,
    this.requires = const [],
    this.referenceValue = 0,
    this.referenceLabel = '',
    this.referenceSource = '',
    this.referenceKind = Confidence.official,
    this.markersNeeded = 3,
    this.quiz = const [],
    this.landCover = const [],
    this.focusZoom,
  });

  final String id;
  final String siteId;
  final String title;

  /// The environmental question the mission explores.
  final String question;

  /// What the player does.
  final String task;

  /// The geospatial or ecological concept explained afterwards.
  final String learning;

  /// Plain-language completion and scoring rule.
  final String rule;
  final MissionType type;
  final int xpPerStar;

  /// Missions that must be completed first (same site chain).
  final List<String> requires;

  /// Area in m² (digitize) or distance in m (measure).
  final double referenceValue;
  final String referenceLabel;
  final String referenceSource;
  final Confidence referenceKind;
  final int markersNeeded;
  final List<QuizQuestion> quiz;
  final List<LandCoverExample> landCover;
  final double? focusZoom;
}
