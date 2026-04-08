import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'group_management_service.dart';
import 'telemetry_service.dart';

class SessionSummary {
  SessionSummary({
    required this.id,
    required this.dateIso,
    required this.trackName,
    this.trackId,
    this.organizerGroupName,
    required this.bestLapMs,
    required this.idealLapMs,
    required this.maxSpeedKmh,
  });

  final String id;
  final String dateIso;
  final String trackName;
  /// Racing track id when saved (optional for older records).
  final String? trackId;
  /// Track-day management group name from rider onboarding when session was saved.
  final String? organizerGroupName;
  final int bestLapMs;
  final int idealLapMs;
  final double maxSpeedKmh;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateIso': dateIso,
        'trackName': trackName,
        if (trackId != null) 'trackId': trackId,
        if (organizerGroupName != null) 'organizerGroupName': organizerGroupName,
        'bestLapMs': bestLapMs,
        'idealLapMs': idealLapMs,
        'maxSpeedKmh': maxSpeedKmh,
      };

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      id: json['id'] as String,
      dateIso: json['dateIso'] as String,
      trackName: json['trackName'] as String,
      trackId: json['trackId'] as String?,
      organizerGroupName: json['organizerGroupName'] as String?,
      bestLapMs: json['bestLapMs'] as int,
      idealLapMs: json['idealLapMs'] as int,
      maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
    );
  }

  /// Whether this session should appear in the given organizer's history.
  bool visibleToOrganizer(String organizerGroupName) {
    final want = organizerGroupName.trim();
    if (want.isEmpty) return false;
    final tagged = this.organizerGroupName?.trim();
    if (tagged != null && tagged.isNotEmpty) {
      return tagged == want;
    }
    final group = GroupManagementService.instance.organizerByName(want);
    if (group == null) return false;
    final day = _calendarDayFromIso(dateIso);
    if (day == null || day != group.assignedDateIso) return false;
    if (trackId != null && trackId!.isNotEmpty) {
      return trackId == group.assignedTrackId;
    }
    return trackName ==
        GroupManagementService.instance.trackNameFor(group.assignedTrackId);
  }

  static String? _calendarDayFromIso(String dateIso) {
    final dt = DateTime.tryParse(dateIso);
    if (dt == null) return null;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

  Future<void> saveSnapshot(
    TelemetrySnapshot snapshot, {
    String? riderOrganizerGroupName,
  }) async {
    final sessions = await loadSessions();
    sessions.insert(
      0,
      SessionSummary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateIso: DateTime.now().toIso8601String(),
        trackName: snapshot.selectedTrack.name,
        trackId: snapshot.selectedTrack.id,
        organizerGroupName: riderOrganizerGroupName,
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
