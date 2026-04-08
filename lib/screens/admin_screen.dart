import 'package:flutter/material.dart';

import '../services/telemetry_service.dart';
import '../widgets/time_formatters.dart';
import '../widgets/track_map_widget.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.telemetryService,
  });

  final TelemetryService telemetryService;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.telemetryService,
      builder: (context, _) {
        final riders = widget.telemetryService.snapshot.riders;
        final data = widget.telemetryService.snapshot;
        final sorted = [...riders]..sort((a, b) => a.bestLap.compareTo(b.bestLap));
        final groups = ['A+', 'A', 'B+', 'B', 'C', 'D'];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Track-Day Organizer Control', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Track-day riders: leaderboard, sector/lap times, and live positions',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 280,
                child: ListView(
                  children: groups.map((group) {
                    final inGroup = sorted.where((r) => r.speedGroup == group).toList();
                    return ExpansionTile(
                      title: Text('Speed Group $group (${inGroup.length})'),
                      children: inGroup.map((rider) {
                        Color? color;
                        if (rider.isSessionBest) color = Colors.red;
                        if (rider.isPersonalBest) color = Colors.orange;
                        return LongPressDraggable<String>(
                          data: rider.id,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Chip(
                              label: Text(rider.displayName),
                              backgroundColor: Colors.white,
                            ),
                          ),
                          child: Card(
                            child: ListTile(
                              title: Text(rider.displayName, style: TextStyle(color: color)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Group: ${rider.speedGroup}'),
                                  Text(
                                    'S1 ${formatDuration(rider.sectors[0])} | '
                                    'S2 ${formatDuration(rider.sectors[1])} | '
                                    'S3 ${formatDuration(rider.sectors[2])}',
                                  ),
                                  Text(
                                    'Last Lap: ${formatDuration(rider.lastLap)} | '
                                    'Best Lap: ${formatDuration(rider.bestLap)}',
                                  ),
                                  Text('Max Speed: ${rider.maxSpeedKmh.toStringAsFixed(1)} km/h'),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Organizer view: all riders, sectors, lap times, and live map for assigned track day.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              const Text('Live Track Map'),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TrackMapWidget(
                      track: data.selectedTrack,
                      riders: riders,
                      telemetryTrail: data.telemetryTrail,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Speed groups (6 levels)'),
              Wrap(
                spacing: 8,
                children: groups
                    .map(
                      (group) => DragTarget<String>(
                        onAcceptWithDetails: (details) {
                          widget.telemetryService
                              .moveRiderToSpeedGroup(details.data, group);
                        },
                        builder: (context, _, __) {
                          return Chip(label: Text('Drop Zone: $group'));
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
