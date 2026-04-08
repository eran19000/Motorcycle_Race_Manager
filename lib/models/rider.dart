class RiderLiveData {
  RiderLiveData({
    required this.id,
    required this.displayName,
    required this.bestLap,
    required this.lastLap,
    required this.sectors,
    required this.maxSpeedKmh,
    required this.positionX,
    required this.positionY,
    required this.speedGroup,
    this.isSessionBest = false,
    this.isPersonalBest = false,
  });

  final String id;
  final String displayName;
  final Duration bestLap;
  final Duration lastLap;
  final List<Duration> sectors;
  final double maxSpeedKmh;
  final double positionX;
  final double positionY;
  final String speedGroup;
  final bool isSessionBest;
  final bool isPersonalBest;

  RiderLiveData copyWith({
    String? id,
    String? displayName,
    Duration? bestLap,
    Duration? lastLap,
    List<Duration>? sectors,
    double? maxSpeedKmh,
    double? positionX,
    double? positionY,
    String? speedGroup,
    bool? isSessionBest,
    bool? isPersonalBest,
  }) {
    return RiderLiveData(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      bestLap: bestLap ?? this.bestLap,
      lastLap: lastLap ?? this.lastLap,
      sectors: sectors ?? this.sectors,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      speedGroup: speedGroup ?? this.speedGroup,
      isSessionBest: isSessionBest ?? this.isSessionBest,
      isPersonalBest: isPersonalBest ?? this.isPersonalBest,
    );
  }
}
