import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'models.dart';

class TrackLibrary {
  TrackLibrary._();
  static final TrackLibrary instance = TrackLibrary._();

  final List<TrackDefinition> tracks = const [
    TrackDefinition(id: 'serres', name: 'Serres', center: LatLng(41.0707, 23.5308)),
    TrackDefinition(id: 'mugello', name: 'Mugello', center: LatLng(43.9975, 11.3719)),
    TrackDefinition(id: 'fazza', name: 'Fazza', center: LatLng(24.2227, 55.7416)),
    TrackDefinition(id: 'arad', name: 'Arad', center: LatLng(31.2582, 35.2144)),
    TrackDefinition(id: 'motorcity', name: 'MotorCity', center: LatLng(24.9518, 55.2432)),
    TrackDefinition(id: 'brno', name: 'Brno', center: LatLng(49.2031, 16.4446)),
    TrackDefinition(id: 'pleven', name: 'Pleven', center: LatLng(43.4096, 24.6173)),
  ];

  TrackDefinition detectNearest(LatLng current) {
    TrackDefinition best = tracks.first;
    var bestDistance = double.maxFinite;
    for (final t in tracks) {
      final d = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        t.center.latitude,
        t.center.longitude,
      );
      if (d < bestDistance) {
        bestDistance = d;
        best = t;
      }
    }
    return best;
  }

  List<LatLng> parseKmlCoordinates(String kml) {
    final coords = <LatLng>[];
    final reg = RegExp(r'<coordinates>([^<]+)</coordinates>', dotAll: true);
    final matches = reg.allMatches(kml);
    for (final m in matches) {
      final block = (m.group(1) ?? '').trim();
      if (block.isEmpty) continue;
      final points = block.split(RegExp(r'\s+'));
      for (final p in points) {
        final ll = p.split(',');
        if (ll.length < 2) continue;
        final lng = double.tryParse(ll[0]);
        final lat = double.tryParse(ll[1]);
        if (lat != null && lng != null) {
          coords.add(LatLng(lat, lng));
        }
      }
    }
    return coords;
  }
}
