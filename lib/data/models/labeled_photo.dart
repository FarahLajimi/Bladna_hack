/// Where a field-evidence record "is". BLADNA never reads GPS.
enum RecordLocation {
  /// No location stored at all.
  none('No location'),

  /// Linked to an investigation in the game (e.g. the Borj Chakir mission).
  /// This is a game record, NOT where the photo was taken.
  missionLink('Linked to a mission (not the photo\'s real location)');

  const RecordLocation(this.label);
  final String label;
}

/// One field-evidence record: a photo of real waste, the category the player
/// chose (a MANUAL label), optional notes, and an optional mission link.
/// This is the raw material for a future waste-recognition model.
class LabeledPhoto {
  const LabeledPhoto({
    required this.id,
    required this.path,
    required this.categoryId,
    required this.timestamp,
    this.note = '',
    this.missionId,
    this.location = RecordLocation.none,
    this.modelPrediction,
    this.modelName,
  });

  final String id;

  /// File path inside the app's private documents folder.
  final String path;

  /// Manual label chosen by the player.
  final String categoryId;
  final DateTime timestamp;
  final String note;
  final String? missionId;
  final RecordLocation location;

  /// A REAL model output, if one was installed when the photo was saved.
  /// Always null in this build (no model ships).
  final String? modelPrediction;
  final String? modelName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'cat': categoryId,
        'ts': timestamp.millisecondsSinceEpoch,
        if (note.isNotEmpty) 'note': note,
        if (missionId != null) 'mission': missionId,
        'loc': location.name,
        if (modelPrediction != null) 'ai': modelPrediction,
        if (modelName != null) 'model': modelName,
      };

  static LabeledPhoto? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final path = raw['path'];
    final cat = raw['cat'];
    final ts = raw['ts'];
    if (id is! String || path is! String || cat is! String || ts is! int) return null;
    final note = raw['note'];
    final mission = raw['mission'];
    final loc = raw['loc'];
    final ai = raw['ai'];
    final model = raw['model'];
    var location = RecordLocation.none;
    for (final l in RecordLocation.values) {
      if (l.name == loc) location = l;
    }
    return LabeledPhoto(
      id: id,
      path: path,
      categoryId: cat,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      note: note is String ? note : '',
      missionId: mission is String ? mission : null,
      location: location,
      modelPrediction: ai is String ? ai : null,
      modelName: model is String ? model : null,
    );
  }
}
