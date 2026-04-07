class RacingTrack {
  const RacingTrack({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.city,
    required this.lengthKm,
    required this.finishLat,
    required this.finishLng,
  });

  final String id;
  final String name;
  final String countryCode;
  final String city;
  final double lengthKm;
  final double finishLat;
  final double finishLng;

  String get label => '$countryCode | $name ($city)';
}
