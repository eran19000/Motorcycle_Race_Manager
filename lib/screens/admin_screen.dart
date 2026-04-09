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
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                height: 320,
                child: ListView(
                  children: groups.map((group) {
                    final inGroup = sorted.where((r) => r.speedGroup == group).toList();
                    return ExpansionTile(
                      title: Text('Speed Group $group (${inGroup.length})'),
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Rider')),
                              DataColumn(label: Text('Group')),
                              DataColumn(label: Text('S1')),
                              DataColumn(label: Text('S2')),
                              DataColumn(label: Text('S3')),
                              DataColumn(label: Text('Last')),
                              DataColumn(label: Text('Best')),
                              DataColumn(label: Text('Max')),
                            ],
                            rows: inGroup.map((rider) {
                              Color? color;
                              if (rider.isSessionBest) color = Colors.red;
                              if (rider.isPersonalBest) color = Colors.orange;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    LongPressDraggable<String>(
                                      data: rider.id,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: Chip(
                                          label: Text(rider.displayName),
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                      child: Text(rider.displayName, style: TextStyle(color: color)),
                                    ),
                                  ),
                                  DataCell(Text(rider.speedGroup)),
                                  DataCell(Text(formatDuration(rider.sectors[0]))),
                                  DataCell(Text(formatDuration(rider.sectors[1]))),
                                  DataCell(Text(formatDuration(rider.sectors[2]))),
                                  DataCell(Text(formatDuration(rider.lastLap))),
                                  DataCell(Text(formatDuration(rider.bestLap))),
                                  DataCell(Text('${rider.maxSpeedKmh.toStringAsFixed(1)} km/h')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
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
              SizedBox(
                height: 300,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
