import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ResponsiveCockpitApp());
}

const _bg = Color(0xFF000000);
const _matteWhite = Color(0xFFF7F7F5);
const _neonBlue = Color(0xFF36D6FF);
const _neonGreen = Color(0xFF3BFF8D);
const _neonPurple = Color(0xFFC265FF);
const _neonOrange = Color(0xFFFFB23F);

class ResponsiveCockpitApp extends StatelessWidget {
  const ResponsiveCockpitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        fontFamily: 'Inter',
      ),
      home: const CockpitScreen(),
    );
  }
}

class CockpitScreen extends StatefulWidget {
  const CockpitScreen({super.key});

  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> {
  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accSub;
  Timer? _clockTimer;

  int _tabIndex = 1;
  int _lapCount = 1;
  double _speedKmh = 0.0;
  double _leanDeg = 0.0;
  double _maxSpeed = 0.0;
  double _maxLean = 0.0;
  double _gForce = 0.0;

  Duration _totalElapsed = Duration.zero;
  Duration _currentLap = Duration.zero;
  Duration _bestLap = const Duration(hours: 9);
  DateTime? _lapStart;
  DateTime? _lastGateTrigger;
  bool _gpsConnected = false;
  double _gpsHz = 0.0;
  DateTime? _lastGpsPointAt;

  Position? _lastPos;
  bool _wasOutsideGate = true;

  // Virtual finish gate (replace with track-calibrated gate as needed)
  static const _gateLat = 31.2582;
  static const _gateLng = 35.2144;
  static const _gateRadiusM = 24.0;
  static const _gateCooldown = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _lapStart = DateTime.now();
    _startClock();
    _startSensors();
    _startGps();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = DateTime.now();
      setState(() {
        _totalElapsed = now.difference(_lapStart!.subtract(_currentLap));
        _currentLap = now.difference(_lapStart!);
      });
    });
  }

  void _startSensors() {
    _gyroSub = gyroscopeEventStream().listen((event) {
      final next = (_leanDeg + (event.y * 2.1)).clamp(0.0, 65.0);
      if (!mounted) return;
      setState(() {
        _leanDeg = next;
        if (_leanDeg > _maxLean) _maxLean = _leanDeg;
      });
    });

    _accSub = accelerometerEventStream().listen((event) {
      final norm = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (!mounted) return;
      setState(() {
        _gForce = (norm / 9.80665).clamp(0.0, 4.0);
      });
    });
  }

  Future<void> _startGps() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((pos) {
      final now = DateTime.now();
      final lastAt = _lastGpsPointAt;
      if (lastAt != null) {
        final dtMs = now.difference(lastAt).inMilliseconds;
        if (dtMs > 0) _gpsHz = 1000 / dtMs;
      }
      _lastGpsPointAt = now;

      final speedKmh = (pos.speed * 3.6).clamp(0.0, 420.0);
      final inGate = Geolocator.distanceBetween(pos.latitude, pos.longitude, _gateLat, _gateLng) <= _gateRadiusM;
      _processLapGate(inGate: inGate, speedKmh: speedKmh, now: now);

      _lastPos = pos;
      if (!mounted) return;
      setState(() {
        _gpsConnected = true;
        _speedKmh = speedKmh;
        if (_speedKmh > _maxSpeed) _maxSpeed = _speedKmh;
      });
    });
  }

  void _processLapGate({
    required bool inGate,
    required double speedKmh,
    required DateTime now,
  }) {
    // Trigger only when rider re-enters gate from outside, with speed threshold and cooldown.
    final cooldownOk = _lastGateTrigger == null || now.difference(_lastGateTrigger!) >= _gateCooldown;
    final speedOk = speedKmh >= 35;
    if (_wasOutsideGate && inGate && cooldownOk && speedOk) {
      _registerLap(now);
      _lastGateTrigger = now;
    }
    _wasOutsideGate = !inGate;
  }

  void _registerLap(DateTime now) {
    final startedAt = _lapStart;
    if (startedAt == null) return;
    final lap = now.difference(startedAt);
    if (lap.inMilliseconds < 10 * 1000) return; // Ignore accidental short laps.

    setState(() {
      if (lap < _bestLap) _bestLap = lap;
      _lapCount += 1;
      _lapStart = now;
      _currentLap = Duration.zero;
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _gpsSub?.cancel();
    _gyroSub?.cancel();
    _accSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;
            final centerCluster = _SpeedTimerCluster(
              speedKmh: _speedKmh,
              lapTime: _formatLap(_currentLap),
              lapCount: _lapCount,
            );

            final leftPanels = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NeonPanel(title: 'BEST LAP', value: _formatLap(_bestLap), color: _neonPurple),
                _NeonPanel(title: 'TOTAL TIME', value: _formatLap(_totalElapsed), color: _neonOrange),
                _NeonPanel(title: 'GPS', value: _gpsConnected ? '${_gpsHz.toStringAsFixed(1)}Hz' : 'Disconnected', color: _neonBlue),
              ],
            );

            final rightPanels = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NeonPanel(title: 'LEAN ANGLE', value: '${_leanDeg.toStringAsFixed(0)}°', color: _neonOrange),
                _NeonPanel(title: 'MAX SPEED', value: '${_maxSpeed.toStringAsFixed(1)} km/h', color: _neonGreen),
                _NeonPanel(
                  title: 'SAVED STATS',
                  value: 'Max Lean ${_maxLean.toStringAsFixed(0)}°\nG-Force ${_gForce.toStringAsFixed(2)}g',
                  color: _neonGreen,
                  multiline: true,
                ),
              ],
            );

            if (isPortrait) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  children: [
                    leftPanels,
                    const SizedBox(height: 10),
                    centerCluster,
                    const SizedBox(height: 10),
                    rightPanels,
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: leftPanels),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: centerCluster),
                  const SizedBox(width: 10),
                  Expanded(child: rightPanels),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0A0A0A),
        indicatorColor: _neonBlue.withValues(alpha: 0.2),
        selectedIndex: _tabIndex,
        onDestinationSelected: (v) => setState(() => _tabIndex = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'HOME'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'LIVE'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'STATS'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'TEAM'),
        ],
      ),
    );
  }

  static String _formatLap(Duration d) {
    if (d.inHours >= 9) return '--:--.---';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000)).toString().padLeft(3, '0');
    return '$m:$s.$ms';
  }
}

class _SpeedTimerCluster extends StatelessWidget {
  const _SpeedTimerCluster({
    required this.speedKmh,
    required this.lapTime,
    required this.lapCount,
  });

  final double speedKmh;
  final String lapTime;
  final int lapCount;

  @override
  Widget build(BuildContext context) {
    final speedNorm = (speedKmh / 320).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090909),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _neonBlue.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(color: _neonBlue.withValues(alpha: 0.2), blurRadius: 20),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1.25,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CustomPaint(
                    painter: _SpeedArcPainter(speedNorm: speedNorm),
                  ),
                ),
                Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(
                    color: _matteWhite,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('LAP', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                      Text('$lapCount', style: const TextStyle(color: Colors.black, fontSize: 52, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('${speedKmh.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black, fontSize: 58, fontWeight: FontWeight.w900)),
                      const Text('km/h', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: _matteWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                lapTime,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonPanel extends StatelessWidget {
  const _NeonPanel({
    required this.title,
    required this.value,
    required this.color,
    this.multiline = false,
  });

  final String title;
  final String value;
  final Color color;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 14),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: multiline ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SpeedArcPainter extends CustomPainter {
  _SpeedArcPainter({required this.speedNorm});
  final double speedNorm;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) * 0.42;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      base,
    );

    final grad = SweepGradient(
      colors: const [Color(0xFF2EFCC5), Color(0xFFFFE43D), Color(0xFFFF4B5C)],
      startAngle: math.pi * 0.75,
      endAngle: math.pi * 2.25,
    );
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..shader = grad.createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * speedNorm,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedArcPainter oldDelegate) {
    return oldDelegate.speedNorm != speedNorm;
  }
}
