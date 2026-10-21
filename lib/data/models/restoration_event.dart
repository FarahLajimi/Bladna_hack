/// Types of journal entries. Older saves may contain other types; those are
/// skipped when loading.
enum RestorationEventType {
  arrival,
  firstSort,
  mission,
  reveal,
  achievement,
  levelUp,
  evidence,
  annotation,
}

/// One saved gameplay event. The journal is built only from these records.
class RestorationEvent {
  const RestorationEvent({
    required this.seq,
    required this.type,
    required this.title,
    required this.note,
    required this.timestamp,
    this.zoneId,
    this.significant = false,
  });

  final int seq;
  final RestorationEventType type;
  final String title;
  final String note;
  final DateTime timestamp;

  /// Site id the event belongs to (field kept as `zone` in JSON).
  final String? zoneId;
  final bool significant;

  String? get siteId => zoneId;

  Map<String, dynamic> toJson() => {
        'seq': seq,
        'type': type.name,
        'title': title,
        'note': note,
        'ts': timestamp.millisecondsSinceEpoch,
        if (zoneId != null) 'zone': zoneId,
        'sig': significant,
      };

  static RestorationEvent? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final typeName = raw['type'];
    RestorationEventType? type;
    for (final t in RestorationEventType.values) {
      if (t.name == typeName) type = t;
    }
    final seq = raw['seq'];
    final title = raw['title'];
    final note = raw['note'];
    final ts = raw['ts'];
    if (type == null || seq is! int || title is! String || note is! String || ts is! int) {
      return null;
    }
    final zone = raw['zone'];
    return RestorationEvent(
      seq: seq,
      type: type,
      title: title,
      note: note,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      zoneId: zone is String ? zone : null,
      significant: raw['sig'] == true,
    );
  }
}
