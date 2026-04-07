import 'package:flutter/material.dart';

import '../services/group_management_service.dart';
import '../services/telemetry_service.dart';
import '../widgets/time_formatters.dart';
import '../widgets/track_map_widget.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.telemetryService});

  final TelemetryService telemetryService;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final GroupManagementService _groupService = GroupManagementService.instance;
  final TextEditingController _newGroupController = TextEditingController();

  @override
  void dispose() {
    _newGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.telemetryService, _groupService]),
      builder: (context, _) {
        final riders = widget.telemetryService.snapshot.riders;
        final data = widget.telemetryService.snapshot;
        final sorted = [...riders]..sort((a, b) => a.bestLap.compareTo(b.bestLap));
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Mode', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Track-Day Organizer Groups (must be paid to open day)',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newGroupController,
                      decoration: const InputDecoration(
                        labelText: 'New organizer group name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      _groupService.addGroup(_newGroupController.text);
                      _newGroupController.clear();
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ..._groupService.groups.map(
                (group) => Card(
                  child: SwitchListTile(
                    title: Text(group.name),
                    subtitle: Text(
                      group.paidForCurrentDay
                          ? 'Paid for this track day'
                          : 'Not paid - cannot open day',
                    ),
                    value: group.paidForCurrentDay,
                    onChanged: (value) => _groupService.setPaid(group.id, value),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Real-time leaderboard and rider positions',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final rider = sorted[index];
                    Color? color;
                    if (rider.isSessionBest) color = Colors.red;
                    if (rider.isPersonalBest) color = Colors.orange;
                    return Card(
                      child: ListTile(
                        title: Text(rider.displayName, style: TextStyle(color: color)),
                        subtitle: Text('Group: ${rider.speedGroup}'),
                        trailing: Text(formatDuration(rider.bestLap)),
                      ),
                    );
                  },
                ),
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
                children: ['A+', 'A', 'B+', 'B', 'C', 'D']
                    .map((group) => Chip(label: Text('Drop Zone: $group')))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
