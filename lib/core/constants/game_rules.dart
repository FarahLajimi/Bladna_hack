/// Every number that drives the game lives here. All values are GAME
/// SCORES — they show learning progress, not real-world impact.
class GameRules {
  /// XP for an item sorted correctly on the first attempt (first time only).
  static const int xpFirstTry = 10;

  /// XP for an item sorted correctly after a retry (first time only).
  static const int xpAfterRetry = 5;

  /// After this many wrong attempts on one item, a learning hint is shown.
  static const int hintAfterWrong = 1;

  /// After this many wrong attempts the answer is revealed (no XP).
  static const int revealAfterWrong = 3;

  /// Items to learn to complete Field Training.
  static const int fieldTrainingItems = 5;

  /// Items per sorting round.
  static const int roundSize = 6;

  /// Field evidence: XP for each record, for the first [recordXpCap] records.
  static const int xpPerRecord = 5;
  static const int recordXpCap = 10;

  /// Cumulative XP needed for each level (index 0 = level 1).
  static const List<int> levelThresholds = [0, 60, 150, 270, 420, 600, 800];

  static const List<String> levelTitles = [
    'Field Trainee',
    'Map Reader',
    'Surveyor',
    'Land Interpreter',
    'Wetland Watcher',
    'Field Investigator',
    'Geomatician',
  ];
}
