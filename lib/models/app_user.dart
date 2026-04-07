class AppUser {
  AppUser({
    required this.userName,
    required this.emailOrPhone,
    required this.bikeModel,
    required this.managementDayGroup,
    required this.anonymousInLeaderboard,
    required this.typicalLapSeconds,
    required this.initialSpeedGroup,
  });

  final String userName;
  final String emailOrPhone;
  final String bikeModel;
  final String managementDayGroup;
  final bool anonymousInLeaderboard;
  final double typicalLapSeconds;
  final String initialSpeedGroup;
}

String inferSpeedGroup(double lapSeconds) {
  if (lapSeconds <= 95) return 'A+';
  if (lapSeconds <= 99) return 'A';
  if (lapSeconds <= 103) return 'B+';
  if (lapSeconds <= 108) return 'B';
  if (lapSeconds <= 114) return 'C';
  return 'D';
}
