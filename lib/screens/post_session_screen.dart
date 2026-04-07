import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/lap_models.dart';
import '../services/session_history_service.dart';
import '../widgets/time_formatters.dart';

class PostSessionScreen extends StatefulWidget {
  const PostSessionScreen({super.key});

  @override
  State<PostSessionScreen> createState() => _PostSessionScreenState();
}

class _PostSessionScreenState extends State<PostSessionScreen> {
  final SessionHistoryService _historyService = SessionHistoryService();
  List<SessionSummary> _saved = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _historyService.loadSessions();
    if (!mounted) return;
    setState(() => _saved = rows);
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sampleSessions();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Saved Sessions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        ..._saved.map(
          (item) => Card(
            child: ListTile(
              title: Text('${item.trackName} - ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(item.dateIso))}'),
              subtitle: Text(
                'Best ${formatDuration(Duration(milliseconds: item.bestLapMs))} | '
                'Ideal ${formatDuration(Duration(milliseconds: item.idealLapMs))}',
              ),
              trailing: Text('${item.maxSpeedKmh.toStringAsFixed(1)} km/h'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Detailed Sample Breakdown', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        ...List.generate(sessions.length, (index) {
          final session = sessions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                'Session ${session.id} - ${DateFormat('yyyy-MM-dd HH:mm').format(session.startTime)}',
              ),
              subtitle: Text(
                'Best ${formatDuration(session.bestLap ?? Duration.zero)} | Ideal ${formatDuration(session.idealLapTime ?? Duration.zero)}',
              ),
              children: [
                ...session.laps.map((lap) => _lapTile(session, lap)),
                const Divider(),
                const ListTile(
                  title: Text('Heatmap'),
                  subtitle: Text('Green: Acceleration, Red: Braking zones'),
                  trailing: Icon(Icons.map),
                ),
                const ListTile(
                  title: Text('Video Sync'),
                  subtitle: Text('Align camera timestamp with telemetry timeline'),
                  trailing: Icon(Icons.video_camera_back),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _lapTile(SessionData session, Lap lap) {
    final bestSectorByIndex = List<Duration>.generate(
      lap.sectors.length,
      (index) => session.laps.map((item) => item.sectors[index]).reduce((a, b) => a < b ? a : b),
    );
    return ListTile(
      title: Text('Lap ${lap.lapNumber}: ${formatDuration(lap.lapTime)}'),
      subtitle: Wrap(
        spacing: 10,
        children: List.generate(lap.sectors.length, (index) {
          final isBest = lap.sectors[index] == bestSectorByIndex[index];
          return Text(
            'S${index + 1} ${formatDuration(lap.sectors[index])}',
            style: TextStyle(color: isBest ? Colors.greenAccent : null),
          );
        }),
      ),
      trailing: Text('${lap.maxSpeedKmh.toStringAsFixed(1)} km/h'),
    );
  }

  List<SessionData> _sampleSessions() {
    return [
      SessionData(
        id: 'A1',
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        laps: [
          Lap(
            lapNumber: 1,
            lapTime: const Duration(minutes: 1, seconds: 45, milliseconds: 322),
            maxSpeedKmh: 241.2,
            sectors: const [
              Duration(seconds: 33, milliseconds: 120),
              Duration(seconds: 36, milliseconds: 840),
              Duration(seconds: 35, milliseconds: 362),
            ],
          ),
          Lap(
            lapNumber: 2,
            lapTime: const Duration(minutes: 1, seconds: 44, milliseconds: 908),
            maxSpeedKmh: 244.6,
            sectors: const [
              Duration(seconds: 32, milliseconds: 980),
              Duration(seconds: 36, milliseconds: 801),
              Duration(seconds: 35, milliseconds: 127),
            ],
          ),
        ],
      ),
    ];
  }
}
