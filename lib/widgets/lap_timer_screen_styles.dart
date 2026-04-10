import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/racing_track.dart';
import '../models/rider.dart';
import '../services/telemetry_service.dart';
import 'time_formatters.dart';
import 'track_map_widget.dart';

/// Visual presets matching the neon / pro lap-timer mockups (landscape-first).
abstract final class LapTimerPalette {
  static const Color bg = Color(0xFF000000);
  static const Color neonPurple = Color(0xFFD080FF);
  static const Color neonOrange = Color(0xFFFFB050);
  static const Color neonCyan = Color(0xFF22D3EE);
  static const Color neonMagenta = Color(0xFFE040FF);
  static const Color neonGreen = Color(0xFF4ADE80);
  static const Color neonRed = Color(0xFFFF6B6B);
  static const Color neonYellow = Color(0xFFFACC15);
  static const Color neonBlue = Color(0xFF38BDF8);
  static const Color panel = Color(0xFF0E0E0E);
}

class LapTimerScreenStyles {
  LapTimerScreenStyles._();

  static String _lapTime(
    TelemetrySnapshot data,
    bool showThousandths,
  ) {
    return formatDuration(
      data.lapElapsed,
      precision:
          showThousandths ? TimerPrecision.millisecond : TimerPrecision.centisecond,
    );
  }

  static String _best(TelemetrySnapshot data, bool showThousandths) {
    if (data.bestLap <= Duration.zero) return '—';
    return formatDuration(
      data.bestLap,
      precision:
          showThousandths ? TimerPrecision.millisecond : TimerPrecision.centisecond,
    );
  }

  static String _gap(TelemetrySnapshot data) {
    final best = data.bestLap;
    if (best <= Duration.zero) return '—';
    final delta = data.lapElapsed - best;
    final sec = delta.inMilliseconds / 1000.0;
    if (delta > Duration.zero) {
      return '+${sec.toStringAsFixed(3)}';
    }
    if (delta < Duration.zero) {
      return sec.toStringAsFixed(3);
    }
    return '+0.000';
  }

  static String _lean(TelemetrySnapshot data) =>
      '${data.leanAngleDeg.round()}°';

  static String _speed(TelemetrySnapshot data) =>
      '${data.speedKmh.round()} km/h';

  static String _gpsLabel(TelemetrySnapshot data) =>
      data.useExternalGps ? '10Hz' : '1Hz';

  static Widget _brandTitle({double scale = 1}) {
    final s = scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MOTORCYCLE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11 * s,
            letterSpacing: 1.4,
            height: 1.05,
          ),
        ),
        Text(
          'RACE MANAGER',
          style: TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w600,
            fontSize: 10 * s,
            letterSpacing: 1.2,
            height: 1.05,
          ),
        ),
      ],
    );
  }

  static Widget _label(String text, {Color color = Colors.white70}) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 10,
        letterSpacing: 0.8,
      ),
    );
  }

  static BoxDecoration _neonBorderDecoration(
    Color neon, {
    Color fill = LapTimerPalette.panel,
  }) {
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: neon.withValues(alpha: 0.95), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: neon.withValues(alpha: 0.42),
          blurRadius: 14,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static Widget _neonTile({
    required Color neon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
    Color fill = LapTimerPalette.panel,
    double valueFontSize = 20,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _neonBorderDecoration(neon, fill: fill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _label(label),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                fontSize: valueFontSize,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _whiteDataTile({
    required String label,
    required String value,
    double valueSize = 26,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: valueSize,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _lapGradientTile(String lap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8E0FF),
            Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: LapTimerPalette.neonPurple.withValues(alpha: 0.25),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LAP:',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.55),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lap,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 36,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _mainWhiteTimer({
    required String text,
    required bool sessionBest,
    String? topLabel,
    List<BoxShadow>? extraShadow,
  }) {
    final glow = <BoxShadow>[
      BoxShadow(
        color: Colors.white.withValues(alpha: sessionBest ? 0.65 : 0.42),
        blurRadius: sessionBest ? 36 : 28,
        spreadRadius: sessionBest ? 2 : 1,
      ),
      BoxShadow(
        color: LapTimerPalette.neonCyan.withValues(alpha: sessionBest ? 0.55 : 0.35),
        blurRadius: sessionBest ? 28 : 18,
      ),
      ...?extraShadow,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: glow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (topLabel != null) ...[
            Text(
              topLabel.toUpperCase(),
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
          ],
          FittedBox(
            fit: BoxFit.contain,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 88,
                height: 1,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectorComparisonBars() {
    const heights = [0.42, 0.72, 0.36, 0.64, 0.52];
    const colors = [
      Color(0xFF4ADE80),
      Color(0xFF38BDF8),
      Color(0xFFFF6B6B),
      Color(0xFF4ADE80),
      Color(0xFFFFB050),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 18,
                  height: 40 * heights[i],
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colors[i], width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: colors[i].withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        _label('BEST SECTOR COMPARISON', color: Colors.white54),
      ],
    );
  }

  /// Style 1 — Multi-split grid (purple session best, orange lean, gradient lap).
  static Widget multiSplit({
    required TelemetrySnapshot data,
    required bool showThousandths,
    required bool sessionBest,
  }) {
    final lapStr = '${data.currentLap}';
    final time = _lapTime(data, showThousandths);
    final best = _best(data, showThousandths);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _brandTitle()),
            Expanded(
              flex: 4,
              child: _neonTile(
                neon: LapTimerPalette.neonPurple,
                label: 'SESSION BEST:',
                value: best,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _neonTile(
                neon: LapTimerPalette.neonOrange,
                label: 'LEAN ANGLE:',
                value: _lean(data),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _lapGradientTile(lapStr),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.center,
                  child: _mainWhiteTimer(
                    text: time,
                    sessionBest: sessionBest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Style 2 — Pure center timer on black with white bloom.
  static Widget pureCenter({
    required TelemetrySnapshot data,
    required bool showThousandths,
    required bool sessionBest,
  }) {
    final time = _lapTime(data, showThousandths);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth * 0.78;
        final h = math.max(120.0, c.maxHeight * 0.58);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: w,
                height: h,
                child: _mainWhiteTimer(
                  text: time,
                  sessionBest: sessionBest,
                  extraShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 48,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SF Pro Display · Inter',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Style 3 — Digital Pro: sector bars, cyan-glow timer, bottom row.
  static Widget digitalPro({
    required TelemetrySnapshot data,
    required bool showThousandths,
    required bool sessionBest,
  }) {
    final time = _lapTime(data, showThousandths);
    final best = _best(data, showThousandths);
    final avg = (data.speedKmh + data.maxSpeedKmh) / 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _brandTitle(scale: 0.95)),
            Expanded(child: Center(child: _sectorComparisonBars())),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'SF Pro · Inter',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _mainWhiteTimer(
            text: time,
            sessionBest: sessionBest,
            topLabel: 'CURRENT LAP TIME',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _whiteDataTile(
                label: 'LAP:',
                value: '${data.currentLap}',
                valueSize: 28,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _whiteDataTile(
                label: 'BEST:',
                value: best,
                valueSize: 22,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _neonTile(
                neon: LapTimerPalette.neonRed,
                label: 'GAP:',
                value: _gap(data),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _neonTile(
                neon: LapTimerPalette.neonGreen,
                label: 'AVG SPEED:',
                value: '${avg.toStringAsFixed(1)} km/h',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Style 4 — Faint map, header actions row, neon telemetry strip.
  static Widget mapHud({
    required TelemetrySnapshot data,
    required bool showThousandths,
    required bool sessionBest,
    required RacingTrack track,
    required List<RiderLiveData> riders,
    required List<TelemetryTrailPoint> trail,
  }) {
    final time = _lapTime(data, showThousandths);
    final best = _best(data, showThousandths);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.22,
              child: TrackMapWidget(
                track: track,
                riders: riders,
                telemetryTrail: trail,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _brandTitle(),
                  const Spacer(),
                  _roundHudIcon(Icons.download_rounded),
                  const SizedBox(width: 8),
                  _roundHudIcon(Icons.layers_outlined),
                  const SizedBox(width: 8),
                  _roundHudIcon(Icons.ios_share_rounded),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: _mainWhiteTimer(
                    text: time,
                    sessionBest: sessionBest,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _neonTile(
                      neon: LapTimerPalette.neonPurple,
                      label: 'BEST:',
                      value: best,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _neonTile(
                      neon: LapTimerPalette.neonOrange,
                      label: 'LEAN:',
                      value: _lean(data),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _neonTile(
                      neon: LapTimerPalette.neonGreen,
                      label: 'SPEED:',
                      value: _speed(data),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _neonTile(
                      neon: LapTimerPalette.neonBlue,
                      label: 'GPS:',
                      value: _gpsLabel(data),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _roundHudIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white70, size: 18),
    );
  }

  /// Style 5 — Circular gauge + stacked cards (team / pro layout).
  static Widget teamGauge({
    required TelemetrySnapshot data,
    required bool showThousandths,
    required bool sessionBest,
  }) {
    final time = _lapTime(data, showThousandths);
    final best = _best(data, showThousandths);
    final session = formatDuration(
      data.elapsed,
      precision: showThousandths
          ? TimerPrecision.millisecond
          : TimerPrecision.centisecond,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _SpeedGaugeCard(
            lap: '${data.currentLap}',
            speed: data.speedKmh.round(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TEAM RED · RACE MANAGER',
                style: TextStyle(
                  color: LapTimerPalette.neonCyan,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  shadows: [
                    Shadow(
                      color: LapTimerPalette.neonCyan.withValues(alpha: 0.65),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 3,
                child: _mainWhiteTimer(
                  text: time,
                  sessionBest: sessionBest,
                  topLabel: 'CURRENT LAP TIME',
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _neonTile(
                        neon: LapTimerPalette.neonMagenta,
                        label: 'BEST LAP:',
                        value: best,
                        valueColor: LapTimerPalette.neonMagenta,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: LapTimerPalette.panel,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Max Speed: ${data.maxSpeedKmh.toStringAsFixed(0)} km/h',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Lean: ${data.leanAngleDeg.toStringAsFixed(0)}°',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _neonTile(
                      neon: LapTimerPalette.neonOrange,
                      label: 'LEAN',
                      value: _lean(data),
                      valueColor: LapTimerPalette.neonOrange,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _neonTile(
                      neon: LapTimerPalette.neonYellow,
                      label: 'TOTAL TIME',
                      value: session,
                      valueColor: LapTimerPalette.neonYellow,
                      valueFontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _neonTile(
                      neon: LapTimerPalette.neonCyan,
                      label: 'GPS',
                      value: _gpsLabel(data),
                      valueColor: LapTimerPalette.neonCyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Style 6 — Team performance board with rider rows and side map.
  static Widget teamPerformanceBoard({
    required TelemetrySnapshot data,
    required bool showThousandths,
    required RacingTrack track,
    required List<RiderLiveData> riders,
    required List<TelemetryTrailPoint> trail,
  }) {
    final visibleRiders = riders.isEmpty ? data.riders : riders;
    return Container(
      decoration: BoxDecoration(
        color: LapTimerPalette.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LapTimerPalette.neonCyan.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: LapTimerPalette.neonCyan.withValues(alpha: 0.22),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'TEAM PERFORMANCE LIVE - MOTO GP STYLE',
                    style: TextStyle(
                      color: LapTimerPalette.neonCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.4,
                      shadows: [
                        Shadow(
                          color: LapTimerPalette.neonCyan.withValues(alpha: 0.65),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    children: [
                      _tinyMetric('TST', _best(data, showThousandths), LapTimerPalette.neonPurple),
                      _tinyMetric('LEAN', _lean(data), LapTimerPalette.neonOrange),
                      _tinyMetric('SPEED', _speed(data), LapTimerPalette.neonGreen),
                      _tinyMetric('TYRE AGE', '${(data.elapsed.inMinutes % 20) + 1} Laps', LapTimerPalette.neonBlue),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: visibleRiders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final r = visibleRiders[i];
                        final status = i % 3 == 0 ? 'Pit Out' : 'On Lap';
                        final gap = i == 0 ? '-0.000' : '+0.${(i + 1) * 132}';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: i == 0
                                  ? LapTimerPalette.neonCyan
                                  : Colors.white24,
                            ),
                            boxShadow: i == 0
                                ? [
                                    BoxShadow(
                                      color: LapTimerPalette.neonCyan.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'RIDER: ${r.displayName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _rowTag(
                                  'CURR',
                                  formatDuration(
                                    data.lapElapsed + Duration(milliseconds: i * 180),
                                    precision: showThousandths
                                        ? TimerPrecision.millisecond
                                        : TimerPrecision.centisecond,
                                  ),
                                  LapTimerPalette.neonCyan,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: _rowTag(
                                  'BEST',
                                  formatDuration(
                                    r.bestLap,
                                    precision: showThousandths
                                        ? TimerPrecision.millisecond
                                        : TimerPrecision.centisecond,
                                  ),
                                  LapTimerPalette.neonPurple,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: _rowTag('SPEED', r.maxSpeedKmh.toStringAsFixed(1), LapTimerPalette.neonGreen),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: _rowTag('LEAN', '${(data.leanAngleDeg - i).round()}°', LapTimerPalette.neonOrange),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '$status  $gap',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.fromLTRB(2, 8, 8, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LapTimerPalette.neonBlue.withValues(alpha: 0.6)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TrackMapWidget(track: track, riders: visibleRiders, telemetryTrail: trail),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tinyMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.9)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }

  static Widget _rowTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static Widget build({
    required int styleId,
    required TelemetrySnapshot data,
    required bool showThousandths,
    required bool sessionBest,
    required RacingTrack track,
    required List<RiderLiveData> riders,
    required List<TelemetryTrailPoint> trail,
  }) {
    switch (styleId.clamp(1, 6)) {
      case 1:
        return multiSplit(
          data: data,
          showThousandths: showThousandths,
          sessionBest: sessionBest,
        );
      case 2:
        return pureCenter(
          data: data,
          showThousandths: showThousandths,
          sessionBest: sessionBest,
        );
      case 3:
        return digitalPro(
          data: data,
          showThousandths: showThousandths,
          sessionBest: sessionBest,
        );
      case 4:
        return mapHud(
          data: data,
          showThousandths: showThousandths,
          sessionBest: sessionBest,
          track: track,
          riders: riders,
          trail: trail,
        );
      case 5:
        return teamGauge(
          data: data,
          showThousandths: showThousandths,
          sessionBest: sessionBest,
        );
      default:
        return teamPerformanceBoard(
          data: data,
          showThousandths: showThousandths,
          track: track,
          riders: riders,
          trail: trail,
        );
    }
  }
}

class _SpeedGaugeCard extends StatelessWidget {
  const _SpeedGaugeCard({
    required this.lap,
    required this.speed,
  });

  final String lap;
  final int speed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(c.maxWidth, c.maxHeight);
        return Center(
          child: CustomPaint(
            painter: _GaugeRingsPainter(),
            child: SizedBox(
              width: size,
              height: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LAP',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    lap,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SPEED',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '$speed',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                      height: 1,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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
}

class _GaugeRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    final rect = Rect.fromCircle(center: center, radius: r * 0.98);
    final sweep = math.pi * 1.25;
    final start = -math.pi * 1.1;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    arcPaint.shader = SweepGradient(
      startAngle: start,
      endAngle: start + sweep,
      colors: const [
        Color(0xFF4ADE80),
        Color(0xFFFACC15),
        Color(0xFFFF6B6B),
      ],
    ).createShader(rect);
    canvas.drawArc(rect, start, sweep, false, arcPaint);

    final cyanArc = Paint()
      ..color = LapTimerPalette.neonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 1.02),
      math.pi * 0.85,
      math.pi * 0.45,
      false,
      cyanArc,
    );

    final whiteFill = Paint()..color = Colors.white;
    canvas.drawCircle(center, r * 0.86, whiteFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
