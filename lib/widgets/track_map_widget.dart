import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import '../models/rider.dart';
import '../models/racing_track.dart';
import '../services/telemetry_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final center = LatLng(track.finishLat, track.finishLng);
    final trackLine = _buildTrackPolyline(track);
    final accelSegments = <Polyline>[];
    final brakeSegments = <Polyline>[];
    final hasLiveTrail = telemetryTrail.length > 3;
    final sourcePoints = hasLiveTrail
        ? telemetryTrail
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(growable: false)
        : trackLine;
    for (var i = 0; i < sourcePoints.length - 1; i++) {
      final segment = [sourcePoints[i], sourcePoints[i + 1]];
      final isAccel = hasLiveTrail
          ? telemetryTrail[i + 1].isAcceleration
          : math.sin((i / (sourcePoints.length - 1)) * 2 * math.pi * 2.4) >= 0;
      if (isAccel) {
        accelSegments.add(
          Polyline(points: segment, strokeWidth: 5, color: Colors.green.shade600),
        );
      } else {
        brakeSegments.add(
          Polyline(points: segment, strokeWidth: 5, color: Colors.red.shade700),
        );
      }
    }
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.3,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.motorcycle_race_manager',
        ),
        PolylineLayer(
          polylines: accelSegments,
        ),
        PolylineLayer(
          polylines: brakeSegments,
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: 8,
              color: Colors.red.withValues(alpha: 0.8),
              borderStrokeWidth: 2,
              borderColor: Colors.black,
            ),
          ],
        ),
        MarkerLayer(
          markers: riders.map((rider) {
            final lat = track.finishLat + (rider.positionY - 0.5) * 0.006;
            final lng = track.finishLng + (rider.positionX - 0.5) * 0.006;
            return Marker(
              point: LatLng(lat, lng),
              width: 110,
              height: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rider.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            );
          }).toList(),
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'Acceleration',
              textStyle: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSourceAttribution(
              'Braking',
              textStyle: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<LatLng> _buildTrackPolyline(RacingTrack selectedTrack) {
    final points = <LatLng>[];
    final centerLat = selectedTrack.finishLat;
    final centerLng = selectedTrack.finishLng;
    final scale = (selectedTrack.lengthKm / 4.0).clamp(0.45, 1.55);
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
}
