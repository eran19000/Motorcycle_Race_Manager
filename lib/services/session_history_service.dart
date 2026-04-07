import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'telemetry_service.dart';

class SessionSummary {
  SessionSummary({
    required this.id,
    required this.dateIso,
    required this.trackName,
    required this.bestLapMs,
    required this.idealLapMs,
    required this.maxSpeedKmh,
  });

  final String id;
  final String dateIso;
  final String trackName;
  final int bestLapMs;
  final int idealLapMs;
  final double maxSpeedKmh;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateIso': dateIso,
        'trackName': trackName,
        'bestLapMs': bestLapMs,
        'idealLapMs': idealLapMs,
        'maxSpeedKmh': maxSpeedKmh,
      };

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      id: json['id'] as String,
      dateIso: json['dateIso'] as String,
      trackName: json['trackName'] as String,
      bestLapMs: json['bestLapMs'] as int,
      idealLapMs: json['idealLapMs'] as int,
      maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
    );
  }
}

class SessionHistoryService {
  static const _storageKey = 'session_history_v1';

  Future<List<SessionSummary>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => SessionSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSnapshot(TelemetrySnapshot snapshot) async {
    final sessions = await loadSessions();
    sessions.insert(
      0,
      SessionSummary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateIso: DateTime.now().toIso8601String(),
        trackName: snapshot.selectedTrack.name,
        bestLapMs: snapshot.bestLap.inMilliseconds,
        idealLapMs: snapshot.idealLap.inMilliseconds,
        maxSpeedKmh: snapshot.maxSpeedKmh,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(sessions.map((item) => item.toJson()).toList()),
    );
  }
}
