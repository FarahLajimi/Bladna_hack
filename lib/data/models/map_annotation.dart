/// A personal note the player pinned on the map (e.g. a change observation
/// in the Time Machine mission). The position is USER-PROVIDED — the player
/// tapped it on the imagery — and is never a GPS reading.
class MapAnnotation {
  const MapAnnotation({
    required this.id,
    required this.lat,
    required this.lon,
    required this.missionId,
    required this.note,
    required this.timestamp,
  });

  final String id;
  final double lat;
  final double lon;
  final String missionId;
  final String note;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lon': lon,
        'mission': missionId,
        'note': note,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  static MapAnnotation? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final lat = raw['lat'];
    final lon = raw['lon'];
    final mission = raw['mission'];
    final note = raw['note'];
    final ts = raw['ts'];
    if (id is! String || lat is! num || lon is! num || mission is! String || note is! String || ts is! int) {
      return null;
    }
    return MapAnnotation(
      id: id,
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      missionId: mission,
      note: note,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
    );
  }
}
