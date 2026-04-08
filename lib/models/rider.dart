class RiderLiveData {
  RiderLiveData({
    required this.id,
    required this.displayName,
    required this.bestLap,
    required this.positionX,
    required this.positionY,
    required this.speedGroup,
    this.isSessionBest = false,
    this.isPersonalBest = false,
  });

  final String id;
  final String displayName;
  final Duration bestLap;
  final double positionX;
  final double positionY;
  final String speedGroup;
  final bool isSessionBest;
  final bool isPersonalBest;

  RiderLiveData copyWith({
    String? id,
    String? displayName,
    Duration? bestLap,
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
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      speedGroup: speedGroup ?? this.speedGroup,
      isSessionBest: isSessionBest ?? this.isSessionBest,
      isPersonalBest: isPersonalBest ?? this.isPersonalBest,
    );
  }
}
