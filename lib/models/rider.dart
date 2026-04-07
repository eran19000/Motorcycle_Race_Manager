class RiderLiveData {
  RiderLiveData({
    required this.displayName,
    required this.bestLap,
    required this.positionX,
    required this.positionY,
    required this.speedGroup,
    this.isSessionBest = false,
    this.isPersonalBest = false,
  });

  final String displayName;
  final Duration bestLap;
  final double positionX;
  final double positionY;
  final String speedGroup;
  final bool isSessionBest;
  final bool isPersonalBest;
}
