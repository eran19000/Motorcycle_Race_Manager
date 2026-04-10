import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../data/track_circuit_geometries.dart';
import '../models/rider.dart';
import '../models/racing_track.dart';
import '../services/telemetry_service.dart';

/// Real map tiles (OpenStreetMap) at the selected circuit, with neon telemetry styling.
///
/// Circuit shape uses [kCircuitPolylinesByTrackId] when defined for that [RacingTrack.id];
/// otherwise a temporary loop around start/finish until you add coordinates in
/// `lib/data/track_circuit_geometries.dart`.
class TrackMapWidget extends StatelessWidget {
  const TrackMapWidget({
    super.key,
    required this.track,
    required this.riders,
    this.telemetryTrail = const [],
  });

  final RacingTrack track;
  final List<RiderLiveData> riders;
  final List<TelemetryTrailPoint> telemetryTrail;

  /// Same as [resolvedCircuitLatLngs] — kept for call sites that used the old static.
  static List<LatLng> buildTrackPolyline(RacingTrack selectedTrack) {
    return resolvedCircuitLatLngs(selectedTrack);
  }

  static LatLng _riderPoint(RacingTrack track, RiderLiveData rider) {
    final lat = track.finishLat + (rider.positionY - 0.5) * 0.006;
    final lng = track.finishLng + (rider.positionX - 0.5) * 0.006;
    return LatLng(lat, lng);
  }

  static const _cyanSeg = Color(0xFF00F0FF);
  static const _greenSeg = Color(0xFF39FF9A);
  static const _redSeg = Color(0xFFFF3355);
  static const _whiteSeg = Color(0xFFE8F0F5);

  @override
  Widget build(BuildContext context) {
    final circuit = resolvedCircuitLatLngs(track);
    final hasLiveTrail = telemetryTrail.length > 3;
    final trailPoints = hasLiveTrail
        ? telemetryTrail.map((p) => LatLng(p.latitude, p.longitude)).toList(growable: false)
        : circuit;

    final closedCircuit = circuitIsClosedLoop(circuit);
    final segmentAccel = <bool>[];
    for (var i = 0; i < trailPoints.length - 1; i++) {
      if (hasLiveTrail) {
        segmentAccel.add(telemetryTrail[i + 1].isAcceleration);
      } else {
        segmentAccel.add(
          math.sin((i / math.max(1, trailPoints.length - 1)) * 2 * math.pi * 2.4) >= 0,
        );
      }
    }
    if (closedCircuit && !hasLiveTrail && trailPoints.length >= 2) {
      segmentAccel.add(
        math.sin(((trailPoints.length - 1) / math.max(1, trailPoints.length)) * 2 * math.pi * 2.4) >= 0,
      );
    }

    final boundsPoints = <LatLng>[
      ...circuit,
      ...trailPoints,
      LatLng(track.finishLat, track.finishLng),
    ];

    final initialFit = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(boundsPoints),
      padding: const EdgeInsets.all(26),
      maxZoom: 18,
    );

    final polylines = <Polyline<Object>>[];

    if (hasLiveTrail && circuit.length >= 2) {
      polylines.add(
        Polyline(
          points: circuit,
          strokeWidth: 3,
          color: Colors.white.withValues(alpha: 0.22),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    if (hasLiveTrail && trailPoints.length >= 2) {
      polylines.add(
        Polyline(
          points: trailPoints,
          strokeWidth: 14,
          color: const Color(0x5522D3EE),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
      polylines.add(
        Polyline(
          points: trailPoints,
          strokeWidth: 8,
          color: const Color(0x3322D3EE),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    } else if (!hasLiveTrail && circuit.length >= 2) {
      final glowPath = closedCircuit ? [...circuit, circuit.first] : circuit;
      polylines.add(
        Polyline(
          points: glowPath,
          strokeWidth: 12,
          color: const Color(0x5522D3EE),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
      polylines.add(
        Polyline(
          points: glowPath,
          strokeWidth: 7,
          color: const Color(0x3322D3EE),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    Color segmentColor(int i, bool accel) {
      if (i % 6 == 0) return _whiteSeg;
      if (accel) return i % 3 == 0 ? _greenSeg : _cyanSeg;
      return _redSeg;
    }

    for (var i = 0; i < trailPoints.length - 1; i++) {
      final a = trailPoints[i];
      final b = trailPoints[i + 1];
      final accel = i < segmentAccel.length ? segmentAccel[i] : true;
      polylines.add(
        Polyline(
          points: [a, b],
          strokeWidth: 5,
          color: segmentColor(i, accel),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    if (closedCircuit && !hasLiveTrail && trailPoints.length >= 2) {
      final i = trailPoints.length - 1;
      final accel = segmentAccel.length > i ? segmentAccel[i] : true;
      polylines.add(
        Polyline(
          points: [trailPoints.last, trailPoints.first],
          strokeWidth: 5,
          color: segmentColor(i, accel),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    if (!hasLiveTrail && circuit.length >= 2) {
      final rim = closedCircuit ? [...circuit, circuit.first] : circuit;
      polylines.add(
        Polyline(
          points: rim,
          strokeWidth: 1.2,
          color: Colors.white.withValues(alpha: 0.35),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    final sectorMarkers = _sectorMarkersAlong(circuit);
    final riderMarkers = <Marker>[];
    final ringColors = [_cyanSeg, const Color(0xFFFACC15), _redSeg];
    for (var r = 0; r < riders.length; r++) {
      final rider = riders[r];
      final p = _riderPoint(track, rider);
      final ring = ringColors[r % ringColors.length];
      riderMarkers.add(
        Marker(
          point: p,
          width: 100,
          height: 52,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ring.withValues(alpha: 0.7)),
                ),
                child: Text(
                  rider.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: 2),
                  color: const Color(0xFF0A1218),
                  boxShadow: [
                    BoxShadow(color: ring.withValues(alpha: 0.45), blurRadius: 8),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  rider.displayName.trim().isEmpty
                      ? '?'
                      : rider.displayName.trim().split(RegExp(r'\s+')).first[0].toUpperCase(),
                  style: TextStyle(
                    color: ring,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: initialFit,
          backgroundColor: const Color(0xFF050A12),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.drag |
                InteractiveFlag.pinchZoom |
                InteractiveFlag.doubleTapZoom |
                InteractiveFlag.flingAnimation,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.motorcycle_race_manager',
          ),
          PolylineLayer(polylines: polylines),
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(track.finishLat, track.finishLng),
                radius: 7,
                color: _redSeg,
                borderStrokeWidth: 1.5,
                borderColor: Colors.white,
              ),
            ],
          ),
          MarkerLayer(markers: [...sectorMarkers, ...riderMarkers]),
          // ignore: prefer_const_constructors — RichAttributionWidget is not const
          RichAttributionWidget(
            attributions: const [
              TextSourceAttribution('OpenStreetMap'),
              TextSourceAttribution(
                'Circuit: track_circuit_geometries.dart',
                prependCopyright: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<Marker> _sectorMarkersAlong(List<LatLng> circuit) {
    if (circuit.length < 4) return [];
    const labels = ['T', 'S', 'T', 'S', 'C'];
    final colors = [_greenSeg, _redSeg, _cyanSeg, const Color(0xFFFFAD00), _greenSeg];
    final step = math.max(3, circuit.length ~/ 7);
    final markers = <Marker>[];
    var li = 0;
    for (var i = 0; i < circuit.length; i += step) {
      final c = colors[li % colors.length];
      final label = labels[li % labels.length];
      final pt = circuit[i];
      markers.add(
        Marker(
          point: pt,
          width: 22,
          height: 22,
          alignment: Alignment.center,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A1018),
              border: Border.all(color: c, width: 1.6),
              boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 6)],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
      li++;
    }
    return markers;
  }
}
