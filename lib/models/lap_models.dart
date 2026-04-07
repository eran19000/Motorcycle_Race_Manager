class Lap {
  Lap({
    required this.lapNumber,
    required this.lapTime,
    required this.maxSpeedKmh,
    required this.sectors,
  });

  final int lapNumber;
  final Duration lapTime;
  final double maxSpeedKmh;
  final List<Duration> sectors;
}

class SessionData {
  SessionData({
    required this.id,
    required this.startTime,
    required this.laps,
  });

  final String id;
  final DateTime startTime;
  final List<Lap> laps;

  Duration? get bestLap {
    if (laps.isEmpty) return null;
    return laps
        .map((lap) => lap.lapTime)
        .reduce((a, b) => a < b ? a : b);
  }

  Duration? get idealLapTime {
    if (laps.isEmpty) return null;
    final sectorCount = laps.first.sectors.length;
    final bestSectors = List<Duration>.generate(
      sectorCount,
      (index) => laps.map((lap) => lap.sectors[index]).reduce((a, b) => a < b ? a : b),
    );
    var total = Duration.zero;
    for (final sector in bestSectors) {
      if (sector != null) {
        total += sector;
      }
    }
    return total;
  }
}
