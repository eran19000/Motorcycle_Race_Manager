import 'package:latlong2/latlong.dart';

class RiderLiveRow {
  RiderLiveRow({
    required this.id,
    required this.name,
    required this.photoEmoji,
    required this.currentLap,
    required this.bestLap,
    required this.speedKmh,
    required this.leanDeg,
    required this.gap,
    required this.bikeTempC,
    required this.position,
  });

  final String id;
  final String name;
  final String photoEmoji;
  final String currentLap;
  final String bestLap;
  final double speedKmh;
  final double leanDeg;
  final String gap;
  final int bikeTempC;
  final LatLng position;
}

class TelemetryPoint {
  TelemetryPoint({
    required this.tsMs,
    required this.lapNo,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.gForce,
    required this.leanDeg,
  });

  final int tsMs;
  final int lapNo;
  final double lat;
  final double lng;
  final double speedKmh;
  final double gForce;
  final double leanDeg;
}

class LapTelemetryStats {
  const LapTelemetryStats({
    required this.maxSpeed,
    required this.maxLean,
    required this.avgSpeed,
  });

  final double maxSpeed;
  final double maxLean;
  final double avgSpeed;
}

class TrackDefinition {
  const TrackDefinition({
    required this.id,
    required this.name,
    required this.center,
  });

  final String id;
  final String name;
  final LatLng center;
}
