import 'dart:math' as math;

import 'package:latlong2/latlong.dart' hide Path;

import '../models/racing_track.dart';
import '../models/track_lat_lng.dart';

/// Real circuit polylines keyed by [RacingTrack.id].
///
/// Add rows here when you have GPS traces (e.g. exported from GeoJSON/KML as
/// `[lat, lng], [lat, lng], ...`). Order should follow the racing line; first
/// point should be near start/finish when possible.
///
/// Example:
/// ```dart
/// const Map<String, List<TrackLatLng>> kCircuitPolylinesByTrackId = {
///   'mugello': [
///     TrackLatLng(43.9978, 11.3714),
///     TrackLatLng(43.9981, 11.3720),
///     // ...
///   ],
/// };
/// ```
const Map<String, List<TrackLatLng>> kCircuitPolylinesByTrackId = {};

/// Circuit path for map drawing: registered geometry, otherwise a temporary loop
/// around the official finish coordinates until real points are added.
List<LatLng> resolvedCircuitLatLngs(RacingTrack track) {
  final raw = kCircuitPolylinesByTrackId[track.id];
  if (raw != null && raw.length >= 2) {
    return raw.map((e) => LatLng(e.latitude, e.longitude)).toList(growable: false);
  }
  return syntheticCircuitAroundFinish(track);
}

List<LatLng> syntheticCircuitAroundFinish(RacingTrack track) {
  final points = <LatLng>[];
  final centerLat = track.finishLat;
  final centerLng = track.finishLng;
  final scale = (track.lengthKm / 4.0).clamp(0.45, 1.55);
  final latRadius = 0.0013 * scale;
  final lngRadius = 0.0022 * scale;

  for (var i = 0; i <= 42; i++) {
    final t = (i / 42) * 2 * math.pi;
    final distortion = 1 + 0.14 * math.sin(t * 3);
    final lat = centerLat + latRadius * math.sin(t) * distortion;
    final lng = centerLng + lngRadius * math.cos(t);
    points.add(LatLng(lat, lng));
  }
  return points;
}

bool circuitIsClosedLoop(List<LatLng> pts) {
  if (pts.length < 3) return false;
  const d = Distance();
  final m = d.as(LengthUnit.Meter, pts.first, pts.last);
  return m < 120;
}
