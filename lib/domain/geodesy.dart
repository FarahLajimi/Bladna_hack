import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Small geodesy toolkit for Sky Lab, on a spherical Earth.
///
/// Radius: mean Earth radius 6,371,008.8 m (IUGG). Spherical formulas are
/// accurate to well under 1 % at city scale — plenty for a game, and the
/// same approach used by common web-GIS libraries.
class Geodesy {
  static const double earthRadius = 6371008.8;

  static double _rad(double deg) => deg * math.pi / 180;

  /// Great-circle distance in metres (haversine).
  static double distance(LatLng a, LatLng b) {
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(h.toDouble())));
  }

  /// Area in m² of a simple polygon ring (open or closed) on the sphere.
  /// Uses the line-integral form of spherical excess (Chamberlain & Duquette).
  static double polygonArea(List<LatLng> ring) {
    if (ring.length < 3) return 0;
    var total = 0.0;
    final n = ring.length;
    for (var i = 0; i < n; i++) {
      final p1 = ring[i];
      final p2 = ring[(i + 1) % n];
      total += _rad(p2.longitude - p1.longitude) *
          (2 + math.sin(_rad(p1.latitude)) + math.sin(_rad(p2.latitude)));
    }
    return (total * earthRadius * earthRadius / 2).abs();
  }

  /// Perimeter in metres of a closed ring.
  static double perimeter(List<LatLng> ring) {
    if (ring.length < 2) return 0;
    var d = 0.0;
    for (var i = 0; i < ring.length; i++) {
      d += distance(ring[i], ring[(i + 1) % ring.length]);
    }
    return d;
  }

  /// Stars for a measurement compared with a reference value:
  /// within 15 % → 3, 30 % → 2, 50 % → 1, otherwise 0 (try again).
  static int stars(double measured, double reference) {
    if (reference <= 0 || measured <= 0) return 0;
    final err = (measured - reference).abs() / reference;
    if (err <= 0.15) return 3;
    if (err <= 0.30) return 2;
    if (err <= 0.50) return 1;
    return 0;
  }

  static String formatArea(double m2) {
    if (m2 >= 1e6) return '${(m2 / 1e6).toStringAsFixed(1)} km²';
    if (m2 >= 1e4) return '${(m2 / 1e4).toStringAsFixed(0)} ha';
    return '${m2.toStringAsFixed(0)} m²';
  }

  static String formatDistance(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(2)} km' : '${m.toStringAsFixed(0)} m';
}
