import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/telemetry_service.dart';
import '../services/session_history_service.dart';
import '../widgets/time_formatters.dart';
import '../widgets/track_map_widget.dart';

class LiveDashboardScreen extends StatefulWidget {
  const LiveDashboardScreen({super.key, required this.telemetryService});

  final TelemetryService telemetryService;

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  bool _showThousandths = false;
  int _layout = 1;
  bool _landscapeMode = false;
  int _timerPreset = 1;
  final SessionHistoryService _historyService = SessionHistoryService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.telemetryService,
      builder: (context, _) {
        final data = widget.telemetryService.snapshot;
        final invert = data.personalBestSectorTriggered;
        final sessionBest = data.sessionBestLapTriggered;
        final bgColor = sessionBest
            ? const Color(0xFF14532D)
            : invert
                ? Colors.white
                : const Color(0xFF000000);
        final fgColor = invert ? Colors.black : Colors.white;

        return Container(
          color: bgColor,
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Racing Dashboard',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: fgColor,
                        ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Demo',
                        style: TextStyle(color: fgColor, fontWeight: FontWeight.w900),
                      ),
                      Switch(
                        value: data.demoMode,
                        onChanged: widget.telemetryService.toggleDemoMode,
                      ),
                      Text(
                        'External Bluetooth GPS',
                        style: TextStyle(color: fgColor, fontWeight: FontWeight.w900),
                      ),
                      Switch(
                        value: data.useExternalGps,
                        onChanged: widget.telemetryService.toggleExternalGps,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _landscapeMode
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _timerView(data, fgColor),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _metric('Speed', '${data.speedKmh.toStringAsFixed(1)} km/h', invert),
                              _metric('Lap', '${data.currentLap}', invert),
                              _metric('Best', formatDuration(data.bestLap, precision: _showThousandths ? TimerPrecision.millisecond : TimerPrecision.centisecond), invert),
                              _metric('Ideal', formatDuration(data.idealLap, precision: _showThousandths ? TimerPrecision.millisecond : TimerPrecision.centisecond), invert),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _timerView(data, fgColor),
              const SizedBox(height: 4),
              if (!_landscapeMode)
                Center(
                  child: Text(
                    widget.telemetryService.externalGpsProviderLabel(),
                    style: TextStyle(color: fgColor, fontWeight: FontWeight.w900),
                  ),
                ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Track: ${data.selectedTrack.label} | ${data.selectedTrack.lengthKm}km',
                  style: TextStyle(color: fgColor, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  if (_layout == 1 || _layout == 3)
                    _metric('Lean Angle', '${data.leanAngleDeg.toStringAsFixed(1)} deg', invert),
                  _metric('Speed', '${data.speedKmh.toStringAsFixed(1)} km/h', invert),
                  if (_layout != 2)
                    _metric('Max Speed', '${data.maxSpeedKmh.toStringAsFixed(1)} km/h', invert),
                  _metric('Current Lap', '${data.currentLap}', invert),
                  _metric(
                    'Best Lap',
                    formatDuration(
                      data.bestLap,
                      precision: _showThousandths
                          ? TimerPrecision.millisecond
                          : TimerPrecision.centisecond,
                    ),
                    invert,
                  ),
                  _metric(
                    'Ideal Time',
                    formatDuration(
                      data.idealLap,
                      precision: _showThousandths
                          ? TimerPrecision.millisecond
                          : TimerPrecision.centisecond,
                    ),
                    invert,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: invert ? Colors.black : Colors.white,
                      foregroundColor: invert ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      widget.telemetryService.setFinishLineFromCurrentLocation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Finish line updated')),
                      );
                    },
                    child: const Text('Set Finish Line'),
                  ),
                  FilledButton(
                    onPressed: () => _openSectorDialog(context),
                    child: const Text('Set Sectors'),
                  ),
                  Chip(
                    side: BorderSide(color: fgColor),
                    backgroundColor: invert ? Colors.black : Colors.grey.shade200,
                    label: Text(
                      data.finishLine == null ? 'Finish Line: not set' : 'Finish Line: set',
                      style: TextStyle(color: fgColor, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Chip(
                    side: BorderSide(color: fgColor),
                    backgroundColor: invert ? Colors.black : Colors.grey.shade200,
                    label: Text(
                      data.currentPosition == null
                          ? 'GPS: no position'
                          : 'GPS: ${data.currentPosition!.latitude.toStringAsFixed(5)}, ${data.currentPosition!.longitude.toStringAsFixed(5)}',
                      style: TextStyle(color: fgColor, fontWeight: FontWeight.w900),
                    ),
                  ),
                  DropdownButton<int>(
                    value: _layout,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Layout 1 - Full')),
                      DropdownMenuItem(value: 2, child: Text('Layout 2 - Race Minimal')),
                      DropdownMenuItem(value: 3, child: Text('Layout 3 - Telemetry Focus')),
                    ],
                    onChanged: (value) => setState(() => _layout = value ?? _layout),
                  ),
                  DropdownButton<int>(
                    value: _timerPreset,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Clock Preset 1')),
                      DropdownMenuItem(value: 2, child: Text('Clock Preset 2')),
                      DropdownMenuItem(value: 3, child: Text('Clock Preset 3')),
                    ],
                    onChanged: (value) => setState(() => _timerPreset = value ?? _timerPreset),
                  ),
                  FilterChip(
                    label: Text(_landscapeMode ? 'Landscape: ON' : 'Landscape: OFF'),
                    selected: _landscapeMode,
                    onSelected: (value) => setState(() => _landscapeMode = value),
                  ),
                  FilterChip(
                    label: Text(_showThousandths ? 'Thousandths: ON' : 'Thousandths: OFF'),
                    selected: _showThousandths,
                    onSelected: (value) => setState(() => _showThousandths = value),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final prefs = await SharedPreferences.getInstance();
                      final org =
                          prefs.getString('active_rider_organizer_group');
                      await _historyService.saveSnapshot(
                        data,
                        riderOrganizerGroupName: org,
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Session snapshot saved to history')),
                      );
                    },
                    child: const Text('Save Session'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TrackMapWidget(
                    track: data.selectedTrack,
                    riders: data.riders,
                    telemetryTrail: data.telemetryTrail,
                  ),
                ),
              ),
              const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metric(String title, String value, bool invert) {
    return Chip(
      label: Text(
        '$title: $value',
        style: TextStyle(
          color: invert ? Colors.white : Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: invert ? Colors.black : Colors.white,
      side: BorderSide(color: invert ? Colors.white : Colors.black),
    );
  }

  Widget _timerView(TelemetrySnapshot data, Color fgColor) {
    final text = formatDuration(
      data.elapsed,
      precision: _showThousandths ? TimerPrecision.millisecond : TimerPrecision.centisecond,
    );
    final style = _timerPreset == 1
        ? const TextStyle(fontSize: 140, fontWeight: FontWeight.w900, color: Colors.black)
        : _timerPreset == 2
            ? const TextStyle(fontSize: 128, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: 2)
            : const TextStyle(fontSize: 116, fontWeight: FontWeight.w900, color: Colors.black);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x5522D3EE), blurRadius: 14)],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            text,
            style: style,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }

  Future<void> _openSectorDialog(BuildContext context) async {
    final targets = widget.telemetryService.sectorSplitTargets;
    final c1 = TextEditingController(text: targets[0].inSeconds.toString());
    final c2 = TextEditingController(text: targets[1].inSeconds.toString());
    final c3 = TextEditingController(text: targets[2].inSeconds.toString());
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Sector Split Targets (seconds)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: c1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sector 1 end')),
            TextField(controller: c2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sector 2 end')),
            TextField(controller: c3, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sector 3 end')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final s1 = int.tryParse(c1.text);
              final s2 = int.tryParse(c2.text);
              final s3 = int.tryParse(c3.text);
              if (s1 == null || s2 == null || s3 == null || s1 <= 0 || s1 >= s2 || s2 >= s3) {
                return;
              }
              widget.telemetryService.setSectorSplitTargets([
                Duration(seconds: s1),
                Duration(seconds: s2),
                Duration(seconds: s3),
              ]);
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
