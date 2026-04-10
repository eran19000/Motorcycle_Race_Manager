import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/telemetry_service.dart';
import '../services/session_history_service.dart';
import '../theme/race_input_theme.dart';
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

  static const _lapLayoutChoices = <({int id, String title, String en})>[
    (id: 1, title: 'מסך A — רשת פיצול', en: 'Multi-split neon'),
    (id: 2, title: 'מסך B — טיימר מרכזי', en: 'Pure center glow'),
    (id: 3, title: 'מסך C — Digital Pro', en: 'Digital Pro'),
    (id: 4, title: 'מסך D — מפה + HUD', en: 'Map HUD'),
    (id: 5, title: 'מסך E — מד + צוות', en: 'Team gauge'),
    (id: 6, title: 'מסך F — לוח ביצועים', en: 'Team performance'),
  ];

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
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        const bgColor = LapTimerPalette.bg;
        const fgColor = Colors.white;

        final lapAreaHeight = isLandscape
            ? MediaQuery.of(context).size.height * 0.72
            : MediaQuery.of(context).size.height * 0.48;

        Widget insetBody(Widget child) {
          if (isLandscape) return child;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          );
        }

        return Container(
          color: bgColor,
          padding: EdgeInsets.fromLTRB(
            isLandscape ? 16 : 0,
            16,
            isLandscape ? 16 : 0,
            16,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isLandscape) ...[
                      insetBody(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Live Racing Dashboard',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: fgColor,
                                    ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                      ),
                      const SizedBox(height: 8),
                      insetBody(
                        FilledButton.tonalIcon(
                          onPressed: () => _openLapScreenLayoutPicker(context),
                          icon: const Icon(Icons.dashboard_customize_outlined),
                          label: const Text('בחירת מסך לפטיימר'),
                          style: FilledButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (isLandscape)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _miniInfo('Lap', '${data.currentLap}'),
                          _miniInfo('Best', formatDuration(
                            data.bestLap,
                            precision: _showThousandths
                                ? TimerPrecision.millisecond
                                : TimerPrecision.centisecond,
                          )),
                          _miniInfo('Speed', data.speedKmh.toStringAsFixed(1)),
                          _miniInfo('Lean', '${data.leanAngleDeg.toStringAsFixed(1)}°'),
                        ],
                      ),
                    SizedBox(
                      height: lapAreaHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          LapTimerScreenStyles.build(
                            styleId: _lapScreenStyle,
                            data: data,
                            showThousandths: _showThousandths,
                            sessionBest: sessionBest,
                            track: data.selectedTrack,
                            riders: data.riders,
                            trail: data.telemetryTrail,
                          ),
                          if (data.sectorUpdateMessage != null)
                            Positioned(
                              top: 6,
                              left: 8,
                              right: 8,
                              child: IgnorePointer(
                                child: Material(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: LapTimerPalette.neonCyan.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: LapTimerPalette.neonCyan,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: LapTimerPalette.neonCyan.withValues(alpha: 0.45),
                                            blurRadius: 14,
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          data.sectorUpdateMessage!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (sessionBest)
                      insetBody(
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
                      ),
                    const SizedBox(height: 8),
                    if (isLandscape)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _miniInfo('Ideal', formatDuration(
                            data.idealLap,
                            precision: _showThousandths
                                ? TimerPrecision.millisecond
                                : TimerPrecision.centisecond,
                          )),
                          _miniInfo('GPS', widget.telemetryService.externalGpsProviderLabel()),
                          _miniInfo('Track', data.selectedTrack.label),
                        ],
                      ),
                    insetBody(
                      Center(
                        child: Text(
                          widget.telemetryService.externalGpsProviderLabel(),
                          style: const TextStyle(
                            color: fgColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    insetBody(
                      Center(
                        child: Text(
                          'Track: ${data.selectedTrack.label} | ${data.selectedTrack.lengthKm}km',
                          style: const TextStyle(
                            color: fgColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_layout != 2)
                      insetBody(Wrap(
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
                      )),
                    if (_layout != 2) const SizedBox(height: 12),
                    insetBody(Wrap(
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
                        if (isLandscape)
                          OutlinedButton.icon(
                            onPressed: () => _openLapScreenLayoutPicker(context),
                            icon: const Icon(Icons.dashboard_customize_outlined, size: 20),
                            label: const Text('מסכי לפטיימר'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF22D3EE)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
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
                    )),
                    const SizedBox(height: 10),
                    insetBody(Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _sensorChip('GPS', data.internalGpsAlive, data.currentPosition != null),
                        _sensorChip('ACC', data.accelerometerAlive, true),
                        _sensorChip('GYRO', data.gyroAlive, true),
                        _sensorChip('BLE', data.externalGpsAlive, data.useExternalGps),
                        _metric('G-Force', '${data.gForce.toStringAsFixed(2)}g'),
                      ],
                    )),
                    const SizedBox(height: 10),
                    if (!isLandscape)
                      insetBody(
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

  Future<void> _openLapScreenLayoutPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      'בחירת מסך לפטיימר',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'ניתן להתאים שמות ותצוגה לפי מוקאפים שתעלה בהמשך.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final o in _lapLayoutChoices)
                    ListTile(
                      selected: _lapScreenStyle == o.id,
                      selectedTileColor: Colors.white.withValues(alpha: 0.06),
                      onTap: () async {
                        Navigator.pop(ctx);
                        setState(() => _lapScreenStyle = o.id);
                        await _persistLapStyle(o.id);
                      },
                      leading: Icon(
                        _lapScreenStyle == o.id
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: const Color(0xFF22D3EE),
                      ),
                      title: Text(
                        o.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        o.en,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniInfo(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x5522D3EE)),
      ),
      child: Text(
        '$title: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: c1,
                keyboardType: TextInputType.number,
                style: RaceInputTheme.typingStyle,
                decoration: const InputDecoration(hintText: 'Sector 1 end'),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: c2,
                keyboardType: TextInputType.number,
                style: RaceInputTheme.typingStyle,
                decoration: const InputDecoration(hintText: 'Sector 2 end'),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: c3,
                keyboardType: TextInputType.number,
                style: RaceInputTheme.typingStyle,
                decoration: const InputDecoration(hintText: 'Sector 3 end'),
              ),
            ],
          ),
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
