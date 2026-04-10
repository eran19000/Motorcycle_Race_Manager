import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/telemetry_service.dart';
import '../services/session_history_service.dart';
import '../widgets/lap_timer_screen_styles.dart';
import '../widgets/time_formatters.dart';
import '../widgets/track_map_widget.dart';

class LiveDashboardScreen extends StatefulWidget {
  const LiveDashboardScreen({super.key, required this.telemetryService});

  final TelemetryService telemetryService;

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  static const _prefLapStyle = 'lap_screen_style';

  bool _showThousandths = false;
  int _layout = 1;
  bool _landscapeMode = false;
  /// 1–5 — preset lap-timer full screens (matches uploaded mockups).
  int _lapScreenStyle = 1;
  final SessionHistoryService _historyService = SessionHistoryService();

  @override
  void initState() {
    super.initState();
    _loadLapStyle();
  }

  Future<void> _loadLapStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_prefLapStyle);
    if (!mounted || v == null) return;
    setState(() => _lapScreenStyle = v.clamp(1, 6));
  }

  Future<void> _persistLapStyle(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefLapStyle, value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.telemetryService,
      builder: (context, _) {
        final data = widget.telemetryService.snapshot;
        final sessionBest = data.sessionBestLapTriggered;

        const bgColor = LapTimerPalette.bg;
        const fgColor = Colors.white;

        final lapAreaHeight = _landscapeMode ? 340.0 : 400.0;

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
                            const Text(
                              'Demo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Switch(
                              value: data.demoMode,
                              onChanged: widget.telemetryService.toggleDemoMode,
                            ),
                            const Text(
                              'External Bluetooth GPS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Switch(
                              value: data.useExternalGps,
                              onChanged: widget.telemetryService.toggleExternalGps,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: lapAreaHeight,
                      child: LapTimerScreenStyles.build(
                        styleId: _lapScreenStyle,
                        data: data,
                        showThousandths: _showThousandths,
                        sessionBest: sessionBest,
                        track: data.selectedTrack,
                        riders: data.riders,
                        trail: data.telemetryTrail,
                      ),
                    ),
                    if (sessionBest)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'SESSION BEST LAP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: LapTimerPalette.neonGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: LapTimerPalette.neonGreen.withValues(alpha: 0.7),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        widget.telemetryService.externalGpsProviderLabel(),
                        style: const TextStyle(
                          color: fgColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Track: ${data.selectedTrack.label} | ${data.selectedTrack.lengthKm}km',
                        style: const TextStyle(
                          color: fgColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_layout != 2)
                      Wrap(
                        spacing: 18,
                        runSpacing: 8,
                        children: [
                          if (_layout == 1 || _layout == 3)
                            _metric(
                              'Lean',
                              '${data.leanAngleDeg.toStringAsFixed(1)}°',
                            ),
                          _metric('Speed', '${data.speedKmh.toStringAsFixed(1)} km/h'),
                          if (_layout != 2)
                            _metric('Max', '${data.maxSpeedKmh.toStringAsFixed(1)} km/h'),
                          _metric('Ideal', formatDuration(
                            data.idealLap,
                            precision: _showThousandths
                                ? TimerPrecision.millisecond
                                : TimerPrecision.centisecond,
                          )),
                        ],
                      ),
                    if (_layout != 2) const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
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
                          side: const BorderSide(color: fgColor),
                          backgroundColor: Colors.white12,
                          label: Text(
                            data.finishLine == null
                                ? 'Finish Line: not set'
                                : 'Finish Line: set',
                            style: const TextStyle(
                              color: fgColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Chip(
                          side: const BorderSide(color: fgColor),
                          backgroundColor: Colors.white12,
                          label: Text(
                            data.currentPosition == null
                                ? 'GPS: no position'
                                : 'GPS: ${data.currentPosition!.latitude.toStringAsFixed(5)}, ${data.currentPosition!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: fgColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        DropdownButton<int>(
                          value: _layout,
                          dropdownColor: const Color(0xFF1A1A1A),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Telemetry row: full')),
                            DropdownMenuItem(value: 2, child: Text('Telemetry row: hidden')),
                            DropdownMenuItem(value: 3, child: Text('Telemetry row: lean focus')),
                          ],
                          onChanged: (value) =>
                              setState(() => _layout = value ?? _layout),
                        ),
                        DropdownButton<int>(
                          value: _lapScreenStyle,
                          dropdownColor: const Color(0xFF1A1A1A),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text('Lap screen A — Multi-split neon'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Lap screen B — Pure center glow'),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text('Lap screen C — Digital Pro'),
                            ),
                            DropdownMenuItem(
                              value: 4,
                              child: Text('Lap screen D — Map HUD'),
                            ),
                            DropdownMenuItem(
                              value: 5,
                              child: Text('Lap screen E — Team gauge'),
                            ),
                            DropdownMenuItem(
                              value: 6,
                              child: Text('Lap screen F — Team performance board'),
                            ),
                          ],
                          onChanged: (value) {
                            final v = (value ?? 1).clamp(1, 6);
                            setState(() => _lapScreenStyle = v);
                            _persistLapStyle(v);
                          },
                        ),
                        FilterChip(
                          label: Text(
                            _landscapeMode ? 'Taller lap area' : 'Standard lap area',
                          ),
                          selected: _landscapeMode,
                          onSelected: (value) =>
                              setState(() => _landscapeMode = value),
                        ),
                        FilterChip(
                          label: Text(
                            _showThousandths ? 'Thousandths: ON' : 'Thousandths: OFF',
                          ),
                          selected: _showThousandths,
                          onSelected: (value) =>
                              setState(() => _showThousandths = value),
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
                              const SnackBar(
                                content: Text('Session snapshot saved to history'),
                              ),
                            );
                          },
                          child: const Text('Save Session'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _sensorChip('GPS', data.internalGpsAlive, data.currentPosition != null),
                        _sensorChip('ACC', data.accelerometerAlive, true),
                        _sensorChip('GYRO', data.gyroAlive, true),
                        _sensorChip('BLE', data.externalGpsAlive, data.useExternalGps),
                        _metric('G-Force', '${data.gForce.toStringAsFixed(2)}g'),
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

  Widget _metric(String title, String value) {
    return Chip(
      label: Text(
        '$title: $value',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFF22D3EE)),
    );
  }

  Widget _sensorChip(String label, bool ok, bool enabled) {
    final color = !enabled
        ? Colors.white54
        : ok
            ? LapTimerPalette.neonGreen
            : LapTimerPalette.neonRed;
    final text = !enabled ? '$label: OFF' : '$label: ${ok ? 'OK' : 'NO DATA'}';
    return Chip(
      side: BorderSide(color: color),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      label: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
            TextField(
              controller: c1,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sector 1 end'),
            ),
            TextField(
              controller: c2,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sector 2 end'),
            ),
            TextField(
              controller: c3,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sector 3 end'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final s1 = int.tryParse(c1.text);
              final s2 = int.tryParse(c2.text);
              final s3 = int.tryParse(c3.text);
              if (s1 == null ||
                  s2 == null ||
                  s3 == null ||
                  s1 <= 0 ||
                  s1 >= s2 ||
                  s2 >= s3) {
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
