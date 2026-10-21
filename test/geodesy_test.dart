import 'package:bladna/data/local_data/world_data.dart';
import 'package:bladna/domain/geodesy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('1° of latitude is about 111.2 km', () {
    expect(Geodesy.distance(const LatLng(0, 0), const LatLng(1, 0)), closeTo(111195, 5));
  });

  test('a 1°×1° cell at the equator is about 12,364 km²', () {
    final a = Geodesy.polygonArea(const [LatLng(0, 0), LatLng(0, 1), LatLng(1, 1), LatLng(1, 0)]);
    expect(a / 1e6, closeTo(12364, 5));
  });

  test('area ignores ring direction and a repeated closing point', () {
    const ring = [LatLng(36.80, 10.20), LatLng(36.80, 10.21), LatLng(36.81, 10.21), LatLng(36.81, 10.20)];
    final a = Geodesy.polygonArea(ring);
    expect(a, closeTo(990000, 2000));
    expect(Geodesy.polygonArea(ring.reversed.toList()), closeTo(a, 1e-6));
    expect(Geodesy.polygonArea([...ring, ring.first]), closeTo(a, 1e-6));
    expect(Geodesy.polygonArea(ring.take(2).toList()), 0);
  });

  test('Zaytuna Mosque → Borj Chakir is about 9.35 km', () {
    final d = Geodesy.distance(siteById(SiteIds.medina).center, siteById(SiteIds.borjChakir).center);
    expect(d / 1000, closeTo(9.35, 0.05));
  });

  test('star bands', () {
    expect(Geodesy.stars(114, 100), 3);
    expect(Geodesy.stars(125, 100), 2);
    expect(Geodesy.stars(60, 100), 1);
    expect(Geodesy.stars(200, 100), 0);
    expect(Geodesy.stars(0, 100), 0);
  });
}
