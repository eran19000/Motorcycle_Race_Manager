class RacingTrack {
  const RacingTrack({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.city,
    required this.lengthKm,
    required this.finishLat,
    required this.finishLng,
    this.sector1Lat,
    this.sector1Lng,
    this.sector2Lat,
    this.sector2Lng,
  });

  final String id;
  final String name;
  final String countryCode;
  final String city;
  final double lengthKm;
  final double finishLat;
  final double finishLng;
  /// End of sector 1 (split 1) — optional; used with [sector1Lng] and sector 2 for GPS splits.
  final double? sector1Lat;
  final double? sector1Lng;
  /// End of sector 2 (split 2).
  final double? sector2Lat;
  final double? sector2Lng;

  bool get hasGpsSectorBeacons =>
      sector1Lat != null &&
      sector1Lng != null &&
      sector2Lat != null &&
      sector2Lng != null;

  String get label => '$countryCode | $name ($city)';
}
