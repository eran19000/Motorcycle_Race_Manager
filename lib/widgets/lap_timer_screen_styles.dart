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

  /// LIVE team board mockup (high-viz neon on OLED black).
  static const Color liveCyan = Color(0xFF00E8FF);
  static const Color livePurple = Color(0xFFBF00FF);
  static const Color liveGreen = Color(0xFF39FF14);
  static const Color liveOrange = Color(0xFFFFAD00);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final portraitDevice =
            MediaQuery.orientationOf(context) == Orientation.portrait;
        final cellLandscape = constraints.maxWidth > constraints.maxHeight;
        final base = cellLandscape ? constraints.maxHeight : constraints.maxWidth;
        final timerFont =
            (base * (cellLandscape ? 0.64 : 0.28)).clamp(64.0, 198.0);

        final timeWidget = portraitDevice
            ? SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 512,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: timerFont,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
              );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: portraitDevice ? 4 : (cellLandscape ? 8 : 12),
            vertical: portraitDevice ? 10 : (cellLandscape ? 10 : 14),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: glow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
              timeWidget,
            ],
          ),
        );
      },
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
    return OrientationBuilder(
      builder: (context, orientation) {
        final portrait = orientation == Orientation.portrait;
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
              child: portrait
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _lapGradientTile(lapStr),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _mainWhiteTimer(
                            text: time,
                            sessionBest: sessionBest,
                          ),
                        ),
                      ],
                    )
                  : Row(
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
      },
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
        final portrait =
            MediaQuery.orientationOf(context) == Orientation.portrait;
        final w = portrait ? c.maxWidth : c.maxWidth * 0.78;
        final h = math.max(120.0, c.maxHeight * (portrait ? 0.72 : 0.58));
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
        LayoutBuilder(
          builder: (context, _) {
            final portrait =
                MediaQuery.orientationOf(context) == Orientation.portrait;
            final edge = portrait ? 2.0 : 8.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(edge, 8, edge, 8),
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
            );
          },
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
    final header = Text(
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
    );
    final bottomTelemetryRow = Row(
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
    );
    final bestAndStatsRow = Row(
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
    );

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 6),
              Expanded(
                flex: 5,
                child: _mainWhiteTimer(
                  text: time,
                  sessionBest: sessionBest,
                  topLabel: 'CURRENT LAP TIME',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 108,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SpeedGaugeCard(
                        lap: '${data.currentLap}',
                        speed: data.speedKmh.round(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: bestAndStatsRow),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              bottomTelemetryRow,
            ],
          );
        }
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
                  header,
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
                    child: bestAndStatsRow,
                  ),
                  const SizedBox(height: 8),
                  bottomTelemetryRow,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Style 6 — LIVE team performance (MotoGP-style board + map).
  static Widget teamPerformanceBoard({
    required TelemetrySnapshot data,
    required bool showThousandths,
    required RacingTrack track,
    required List<RiderLiveData> riders,
    required List<TelemetryTrailPoint> trail,
  }) {
    final visibleRiders = riders.isEmpty ? data.riders : riders;
    final prec = showThousandths ? TimerPrecision.millisecond : TimerPrecision.centisecond;
    final tyreLaps = (data.elapsed.inMinutes % 20) + 1;

    Widget leaderboardColumn({required bool compact}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _teamLiveHeaderRow(data: data, showThousandths: showThousandths, tyreLaps: tyreLaps),
          SizedBox(height: compact ? 6 : 10),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: visibleRiders.length,
              separatorBuilder: (_, __) => SizedBox(height: compact ? 5 : 7),
              itemBuilder: (context, i) {
                return _teamLiveRiderRow(
                  rider: visibleRiders[i],
                  index: i,
                  isLeader: i == 0,
                  precision: prec,
                  compact: compact,
                );
              },
            ),
          ),
        ],
      );
    }

    Widget mapPane({EdgeInsetsGeometry? margin}) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LapTimerPalette.liveCyan.withValues(alpha: 0.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: LapTimerPalette.liveCyan.withValues(alpha: 0.2),
              blurRadius: 14,
            ),
          ],
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
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _mapHudIconButton(Icons.add),
                  _mapHudIconButton(Icons.remove),
                  _mapHudIconButton(Icons.my_location),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: LapTimerPalette.bg,
      child: OrientationBuilder(
        builder: (context, o) {
          if (o == Orientation.portrait) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: leaderboardColumn(compact: true)),
                  const SizedBox(height: 8),
                  SizedBox(height: 160, child: mapPane()),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: leaderboardColumn(compact: false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: mapPane(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _mapHudIconButton(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(side: BorderSide(color: Color(0x5522D3EE))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: LapTimerPalette.liveCyan),
          ),
        ),
      ),
    );
  }

  static Widget _teamLiveHeaderRow({
    required TelemetrySnapshot data,
    required bool showThousandths,
    required int tyreLaps,
  }) {
    final best = _best(data, showThousandths);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'TEAM RED - RIDERS',
          style: TextStyle(
            color: LapTimerPalette.liveCyan,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.6,
            shadows: [
              Shadow(
                color: LapTimerPalette.liveCyan.withValues(alpha: 0.75),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const Spacer(),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _teamLiveHeaderChip('T.BST', best),
                _teamLiveHeaderChip('LEAN', _lean(data)),
                _teamLiveHeaderChip('SPEED', '${data.maxSpeedKmh.round()} km/h'),
                _teamLiveHeaderChip('TYRE_AGE', '$tyreLaps Laps'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _teamLiveHeaderChip(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        '$k: $v',
        style: TextStyle(
          color: LapTimerPalette.liveCyan.withValues(alpha: 0.92),
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.2,
          shadows: [
            Shadow(
              color: LapTimerPalette.liveCyan.withValues(alpha: 0.35),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _teamLiveFlags = ['🇬🇧', '🇮🇹', '🇪🇸', '🇫🇷', '🇯🇵', '🇺🇸'];

  static Widget _teamLiveRiderRow({
    required RiderLiveData rider,
    required int index,
    required bool isLeader,
    required TimerPrecision precision,
    required bool compact,
  }) {
    final statuses = ['Pit Out', 'On Lap', 'Out Lap'];
    final status = statuses[index % statuses.length];
    final gapStr = index == 0 ? '-0.000' : '+${(index * 0.132).toStringAsFixed(3)}';
    final gapColor = index == 0 ? LapTimerPalette.liveGreen : LapTimerPalette.neonRed;
    final curr = formatDuration(rider.lastLap, precision: precision);
    final best = formatDuration(rider.bestLap, precision: precision);
    final leanDeg = (48 - index * 2).clamp(32, 54);
    final bikeTemp = 88 + index * 2;
    final riderTyre = 4 + index * 3;
    final flag = _teamLiveFlags[index % _teamLiveFlags.length];
    final initials = rider.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    final borderColor = isLeader ? LapTimerPalette.liveCyan : Colors.white.withValues(alpha: 0.22);
    final glow = isLeader
        ? [
            BoxShadow(
              color: LapTimerPalette.liveCyan.withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ]
        : <BoxShadow>[];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7, vertical: compact ? 5 : 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isLeader ? 1.4 : 1),
        boxShadow: glow,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 520;
          final riderBlock = SizedBox(
            width: narrow ? 56 : 72,
            child: Row(
              children: [
                Container(
                  width: narrow ? 30 : 34,
                  height: narrow ? 30 : 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: LapTimerPalette.liveCyan.withValues(alpha: 0.85), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: LapTimerPalette.liveCyan.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      color: LapTimerPalette.liveCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: narrow ? 10 : 11,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rider.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          height: 1.05,
                        ),
                      ),
                      Text(
                        flag,
                        style: const TextStyle(fontSize: 12, height: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final cells = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              riderBlock,
              SizedBox(width: compact ? 4 : 6),
              Expanded(
                flex: 2,
                child: _teamLiveWhiteLapCell(label: 'CURR_LAP', value: curr, compact: compact),
              ),
              SizedBox(width: compact ? 3 : 5),
              Expanded(
                flex: 2,
                child: _teamLiveNeonMetricCell(
                  label: 'BEST_LAP',
                  value: best,
                  border: LapTimerPalette.livePurple,
                  valueColor: LapTimerPalette.livePurple,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 3 : 5),
              Expanded(
                flex: 2,
                child: _teamLiveNeonMetricCell(
                  label: 'SPEED',
                  value: '${rider.maxSpeedKmh.toStringAsFixed(1)} km/h',
                  border: LapTimerPalette.liveGreen,
                  valueColor: LapTimerPalette.liveGreen,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 3 : 5),
              Expanded(
                flex: 2,
                child: _teamLiveNeonMetricCell(
                  label: 'LEAN',
                  value: '$leanDeg°',
                  border: LapTimerPalette.liveOrange,
                  valueColor: LapTimerPalette.liveOrange,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 3 : 5),
              Expanded(
                flex: 3,
                child: _teamLiveStatusPanel(
                  status: status,
                  gapStr: gapStr,
                  gapColor: gapColor,
                  bikeTemp: bikeTemp,
                  tyreLaps: riderTyre,
                  compact: compact,
                ),
              ),
            ],
          );

          if (narrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: 620, child: cells),
            );
          }
          return cells;
        },
      ),
    );
  }

  static Widget _teamLiveWhiteLapCell({
    required String label,
    required String value,
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.55),
              fontWeight: FontWeight.w800,
              fontSize: compact ? 6.5 : 7,
              letterSpacing: 0.3,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _teamLiveNeonMetricCell({
    required String label,
    required String value,
    required Color border,
    required Color valueColor,
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border.withValues(alpha: 0.95), width: 1.1),
        boxShadow: [
          BoxShadow(color: border.withValues(alpha: 0.28), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: border.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              fontSize: compact ? 6.5 : 7,
              letterSpacing: 0.2,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 9 : 10,
                height: 1,
                shadows: [
                  Shadow(color: valueColor.withValues(alpha: 0.45), blurRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _teamLiveStatusPanel({
    required String status,
    required String gapStr,
    required Color gapColor,
    required int bikeTemp,
    required int tyreLaps,
    required bool compact,
  }) {
    final fs = compact ? 6.5 : 7.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LapTimerPalette.liveCyan.withValues(alpha: 0.9), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: LapTimerPalette.liveCyan.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _teamLiveStatusLine('STATUS', status, LapTimerPalette.liveCyan, fs),
          _teamLiveStatusLine('GAP', gapStr, gapColor, fs),
          _teamLiveStatusLine('BIKE_TEMP', '$bikeTemp°C', LapTimerPalette.liveCyan, fs),
          _teamLiveStatusLine('TYRE_AGE', '$tyreLaps Laps', LapTimerPalette.liveCyan, fs),
        ],
      ),
    );
  }

  static Widget _teamLiveStatusLine(String k, String v, Color vColor, double labelFs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w800,
            fontSize: labelFs,
          ),
          children: [
            TextSpan(text: '$k: '),
            TextSpan(
              text: v,
              style: TextStyle(
                color: vColor,
                fontWeight: FontWeight.w900,
                fontSize: labelFs + 0.5,
                shadows: [
                  Shadow(color: vColor.withValues(alpha: 0.4), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
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
