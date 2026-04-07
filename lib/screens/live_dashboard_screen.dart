import 'package:flutter/material.dart';

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
  TimerPrecision _precision = TimerPrecision.millisecond;
  int _layout = 1;
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
            ? Colors.green
            : invert
                ? Colors.black
                : Colors.white;
        final fgColor = invert ? Colors.white : Colors.black;

        return Container(
          color: bgColor,
          padding: const EdgeInsets.all(16),
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
              const Spacer(flex: 2),
              Center(
                child: Text(
                  formatDuration(data.elapsed, precision: _precision),
                  style: TextStyle(
                    fontSize: 104,
                    fontWeight: FontWeight.w900,
                    color: fgColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 20),
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
                  _metric('Best Lap', formatDuration(data.bestLap, precision: _precision), invert),
                  _metric('Ideal Time', formatDuration(data.idealLap, precision: _precision), invert),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: invert ? Colors.white : Colors.black,
                      foregroundColor: invert ? Colors.black : Colors.white,
                    ),
                    onPressed: widget.telemetryService.setFinishLineFromCurrentLocation,
                    child: const Text('Set Finish Line'),
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
                  DropdownButton<TimerPrecision>(
                    value: _precision,
                    items: const [
                      DropdownMenuItem(
                        value: TimerPrecision.centisecond,
                        child: Text('Precision: 0.01s'),
                      ),
                      DropdownMenuItem(
                        value: TimerPrecision.millisecond,
                        child: Text('Precision: 0.001s'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _precision = value ?? _precision),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await _historyService.saveSnapshot(data);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Session snapshot saved to history')),
                      );
                    },
                    child: const Text('Save Session'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TrackMapWidget(
                    track: data.selectedTrack,
                    riders: data.riders,
                    telemetryTrail: data.telemetryTrail,
                  ),
                ),
              ),
              const Spacer(),
            ],
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
      backgroundColor: invert ? Colors.black : Colors.grey.shade200,
      side: BorderSide(color: invert ? Colors.white : Colors.black),
    );
  }
}
