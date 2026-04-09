import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'models.dart';
import 'telemetry_db.dart';
import 'track_library.dart';

const _kBg = Color(0xFF000000);
const _kWhiteBlock = Color(0xFFFFFFFF);
const _kBlue = Color(0xFF2ED6FF);
const _kGreen = Color(0xFF25F381);
const _kRed = Color(0xFFFF4B5C);
const _kPurple = Color(0xFFC85BFF);

class NeonRaceApp extends StatelessWidget {
  const NeonRaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _kBg,
        fontFamily: 'Inter',
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF111111),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _login = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              color: const Color(0xFF080808),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: _kBlue, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _login
                    ? _LoginForm(onSwitch: () => setState(() => _login = false))
                    : _RegisterForm(onSwitch: () => setState(() => _login = true)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.onSwitch});
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('MOTORCYCLE RACE MANAGER', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password')),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const NeonHome()),
          ),
          child: const Text('LOG IN'),
        ),
        TextButton(onPressed: onSwitch, child: const Text('Create account')),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({required this.onSwitch});
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('REGISTER RIDER', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: 'Rider Name')),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: 'Bike Model')),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: 'Email / Phone')),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const NeonHome()),
          ),
          child: const Text('CREATE ACCOUNT'),
        ),
        TextButton(onPressed: onSwitch, child: const Text('Back to login')),
      ],
    );
  }
}

class NeonHome extends StatefulWidget {
  const NeonHome({super.key});

  @override
  State<NeonHome> createState() => _NeonHomeState();
}

class _NeonHomeState extends State<NeonHome> {
  int tab = 0;
  late final RaceEngine engine;

  @override
  void initState() {
    super.initState();
    engine = RaceEngine()..start();
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: _kBg,
            title: Text(
              'Track: ${engine.detectedTrack.name}',
              style: const TextStyle(color: _kBlue, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  final c = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Import KML'),
                      content: TextField(
                        controller: c,
                        maxLines: 8,
                        decoration: const InputDecoration(hintText: 'Paste KML here...'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            engine.importKml(c.text);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Import'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file, color: _kGreen),
              ),
            ],
          ),
          body: switch (tab) {
            0 => _LiveTimerView(engine: engine),
            1 => _OrganizerTeamView(engine: engine),
            2 => _NanoBananaView(engine: engine),
            _ => _AiPanel(engine: engine),
          },
          bottomNavigationBar: NavigationBar(
            backgroundColor: const Color(0xFF070707),
            indicatorColor: _kBlue.withValues(alpha: 0.22),
            selectedIndex: tab,
            onDestinationSelected: (v) => setState(() => tab = v),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.timer), label: 'Live'),
              NavigationDestination(icon: Icon(Icons.table_view), label: 'Team'),
              NavigationDestination(icon: Icon(Icons.route), label: 'NANO'),
              NavigationDestination(icon: Icon(Icons.smart_toy), label: 'AI'),
            ],
          ),
        );
      },
    );
  }
}

class _LiveTimerView extends StatefulWidget {
  const _LiveTimerView({required this.engine});
  final RaceEngine engine;

  @override
  State<_LiveTimerView> createState() => _LiveTimerViewState();
}

class _LiveTimerViewState extends State<_LiveTimerView> {
  int layout = 0;

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    return OrientationBuilder(
      builder: (context, orientation) {
        final landscape = orientation == Orientation.landscape;
        final timer = _BigTimer(value: e.currentLapTime);
        final info = Wrap(
          alignment: WrapAlignment.center,
          children: [
            _DataChip(label: 'LAP', value: '${e.lapNo}', color: _kBlue),
            _DataChip(label: 'BEST', value: e.bestLapTime, color: _kPurple),
            _DataChip(label: 'SPEED', value: '${e.speedKmh.toStringAsFixed(1)} km/h', color: _kGreen),
            _DataChip(label: 'LEAN', value: '${e.leanDeg.toStringAsFixed(0)}°', color: Colors.orange),
          ],
        );

        Widget content;
        switch (layout) {
          case 1:
            content = landscape
                ? Row(
                    children: [
                      Expanded(child: _DataChip(label: 'LAP', value: '${e.lapNo}', color: _kBlue, large: true)),
                      Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [timer, info])),
                      Expanded(child: _DataChip(label: 'RIDER CHOICE', value: e.riderChoice, color: _kPurple, large: true)),
                    ],
                  )
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [timer, info]);
          case 2:
            content = landscape
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [const _AnalogDial(), timer, info],
                  )
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const _AnalogDial(), const SizedBox(height: 14), timer, info]);
          case 3:
            content = Center(child: timer);
          default:
            content = Column(mainAxisAlignment: MainAxisAlignment.center, children: [timer, const SizedBox(height: 14), info]);
        }
        return GestureDetector(
          onDoubleTap: () => setState(() => layout = (layout + 1) % 4),
          child: Container(
            decoration: const BoxDecoration(color: _kBg),
            child: Center(child: SingleChildScrollView(child: content)),
          ),
        );
      },
    );
  }
}

class _OrganizerTeamView extends StatelessWidget {
  const _OrganizerTeamView({required this.engine});
  final RaceEngine engine;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final landscape = orientation == Orientation.landscape;
        final left = ListView.builder(
          itemCount: engine.riders.length,
          itemBuilder: (context, i) {
            final r = engine.riders[i];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBlue.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Text(r.photoEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.name)),
                  _smallBlock('CUR', r.currentLap, _kWhiteBlock, Colors.black),
                  const SizedBox(width: 6),
                  _smallBlock('BEST', r.bestLap, _kPurple, Colors.white),
                  const SizedBox(width: 6),
                  _smallBlock('SPD', '${r.speedKmh.toStringAsFixed(1)}', _kGreen, Colors.black),
                  const SizedBox(width: 6),
                  _smallBlock('LEAN', '${r.leanDeg.toStringAsFixed(0)}°', Colors.orange, Colors.black),
                  const SizedBox(width: 6),
                  Text('Gap ${r.gap}\nTemp ${r.bikeTempC}°'),
                ],
              ),
            );
          },
        );

        final right = FlutterMap(
          options: MapOptions(initialCenter: engine.mapCenter, initialZoom: 15),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            PolylineLayer(polylines: [
              Polyline(points: engine.trackPolyline, color: _kBlue.withValues(alpha: 0.7), strokeWidth: 4),
            ]),
            MarkerLayer(
              markers: engine.riders
                  .map(
                    (r) => Marker(
                      point: r.position,
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kGreen),
                        ),
                        child: Center(child: Text(r.photoEmoji)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );

        if (landscape) {
          return Row(
            children: [
              Expanded(flex: 3, child: left),
              Expanded(flex: 2, child: right),
            ],
          );
        }
        return Column(
          children: [
            Expanded(flex: 3, child: left),
            Expanded(flex: 2, child: right),
          ],
        );
      },
    );
  }
}

class _NanoBananaView extends StatefulWidget {
  const _NanoBananaView({required this.engine});
  final RaceEngine engine;

  @override
  State<_NanoBananaView> createState() => _NanoBananaViewState();
}

class _NanoBananaViewState extends State<_NanoBananaView> {
  int? selectedLap;
  List<TelemetryPoint> points = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final laps = await TelemetryDb.instance.laps();
    final lap = laps.isNotEmpty ? laps.first : 1;
    final data = await TelemetryDb.instance.pointsForLap(lap);
    if (!mounted) return;
    setState(() {
      selectedLap = lap;
      points = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.engine.statsFor(points);
    final lines = <Polyline>[];
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final delta = b.speedKmh - a.speedKmh;
      lines.add(
        Polyline(
          points: [LatLng(a.lat, a.lng), LatLng(b.lat, b.lng)],
          strokeWidth: 5,
          color: delta < -0.6 ? _kRed : (delta > 0.6 ? _kGreen : _kBlue),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              const Text('NANO-BANANA', style: TextStyle(color: _kBlue, fontWeight: FontWeight.bold)),
              const SizedBox(width: 14),
              Text('Lap ${selectedLap ?? '-'}'),
              const Spacer(),
              OutlinedButton(onPressed: _load, child: const Text('Refresh')),
            ],
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: widget.engine.mapCenter, initialZoom: 15),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                PolylineLayer(polylines: lines),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _telemetryStat('Max Speed', '${stats.maxSpeed.toStringAsFixed(1)} km/h')),
              Expanded(child: _telemetryStat('Max Lean', '${stats.maxLean.toStringAsFixed(1)}°')),
              Expanded(child: _telemetryStat('Avg Speed', '${stats.avgSpeed.toStringAsFixed(1)} km/h')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiPanel extends StatefulWidget {
  const _AiPanel({required this.engine});
  final RaceEngine engine;

  @override
  State<_AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<_AiPanel> {
  final ctrl = TextEditingController(text: 'Analyze braking points and suggest line improvements.');
  String result = 'Gemini AI panel ready.';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Gemini AI Coach', style: TextStyle(fontSize: 20, color: _kPurple)),
          const SizedBox(height: 10),
          TextField(controller: ctrl, maxLines: 4),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  setState(() {
                    result =
                        'Suggested by AI: Brake 8m earlier at T3, open throttle progressively from apex, and reduce max lean by ~2° in sector 2 to improve exit speed.';
                  });
                },
                child: const Text('Analyze'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: _kPurple.withValues(alpha: 0.7)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(child: Text(result)),
            ),
          ),
        ],
      ),
    );
  }
}

class RaceEngine extends ChangeNotifier {
  int lapNo = 14;
  String currentLapTime = '01:32.456';
  String bestLapTime = '01:31.980';
  String riderChoice = 'LEAN';
  double speedKmh = 142.3;
  double leanDeg = 48;
  LatLng mapCenter = const LatLng(31.2582, 35.2144);
  TrackDefinition detectedTrack = TrackLibrary.instance.tracks.first;
  List<LatLng> importedKml = const [];

  final List<RiderLiveRow> riders = [];
  List<LatLng> get trackPolyline => importedKml.isNotEmpty ? importedKml : _defaultTrack;

  StreamSubscription<Position>? _posSub;
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _ticker;
  double _gForce = 0;
  int _seconds = 92;

  final List<LatLng> _defaultTrack = const [
    LatLng(31.2582, 35.2144),
    LatLng(31.2590, 35.2160),
    LatLng(31.2600, 35.2164),
    LatLng(31.2606, 35.2152),
    LatLng(31.2599, 35.2137),
    LatLng(31.2582, 35.2144),
  ];

  void start() {
    riders.addAll(List.generate(7, (i) {
      return RiderLiveRow(
        id: 'r$i',
        name: 'Rider ${i + 1}',
        photoEmoji: '🏍️',
        currentLap: '01:32.${300 + i}',
        bestLap: '01:31.${900 + i}',
        speedKmh: 140 + i.toDouble(),
        leanDeg: 46 + (i % 3).toDouble(),
        gap: i == 0 ? '+0.000' : '+0.${100 + i}',
        bikeTempC: 90 + i,
        position: LatLng(31.2582 + i * 0.0003, 35.2144 + i * 0.0002),
      );
    }));
    _listenSensors();
    _listenGps();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _listenSensors() {
    _accSub = accelerometerEvents.listen((e) {
      _gForce = (sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.81).clamp(0.0, 3.0);
    });
    _gyroSub = gyroscopeEvents.listen((e) {
      leanDeg = (leanDeg + e.y * 1.6).clamp(0.0, 65.0);
      notifyListeners();
    });
  }

  Future<void> _listenGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0),
    ).listen((p) async {
      mapCenter = LatLng(p.latitude, p.longitude);
      speedKmh = (p.speed * 3.6).clamp(0, 360);
      detectedTrack = TrackLibrary.instance.detectNearest(mapCenter);
      await TelemetryDb.instance.insertPoint(
        TelemetryPoint(
          tsMs: DateTime.now().millisecondsSinceEpoch,
          lapNo: lapNo,
          lat: p.latitude,
          lng: p.longitude,
          speedKmh: speedKmh,
          gForce: _gForce,
          leanDeg: leanDeg,
        ),
      );
      _animateRiders();
      notifyListeners();
    });
  }

  void _animateRiders() {
    final rnd = Random();
    for (var i = 0; i < riders.length; i++) {
      final r = riders[i];
      riders[i] = RiderLiveRow(
        id: r.id,
        name: r.name,
        photoEmoji: r.photoEmoji,
        currentLap: currentLapTime,
        bestLap: bestLapTime,
        speedKmh: (speedKmh - (i * 0.9)).clamp(60, 350),
        leanDeg: (leanDeg - i * 0.4).clamp(0, 65),
        gap: '+0.${(rnd.nextInt(70) + 20)}',
        bikeTempC: 88 + rnd.nextInt(12),
        position: LatLng(mapCenter.latitude + (i * 0.0002), mapCenter.longitude + (i * 0.00015)),
      );
    }
  }

  void _tick() {
    _seconds++;
    final min = (_seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_seconds % 60).toString().padLeft(2, '0');
    final ms = (Random().nextInt(999)).toString().padLeft(3, '0');
    currentLapTime = '$min:$sec.$ms';
    notifyListeners();
  }

  LapTelemetryStats statsFor(List<TelemetryPoint> pts) {
    if (pts.isEmpty) {
      return const LapTelemetryStats(maxSpeed: 0, maxLean: 0, avgSpeed: 0);
    }
    var maxSpeed = 0.0;
    var maxLean = 0.0;
    var sum = 0.0;
    for (final p in pts) {
      if (p.speedKmh > maxSpeed) maxSpeed = p.speedKmh;
      if (p.leanDeg > maxLean) maxLean = p.leanDeg;
      sum += p.speedKmh;
    }
    return LapTelemetryStats(maxSpeed: maxSpeed, maxLean: maxLean, avgSpeed: sum / pts.length);
  }

  void importKml(String rawKml) {
    importedKml = TrackLibrary.instance.parseKmlCoordinates(rawKml);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _posSub?.cancel();
    _accSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }
}

class _BigTimer extends StatelessWidget {
  const _BigTimer({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _kWhiteBlock,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.white24, blurRadius: 20)],
      ),
      child: FittedBox(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 86,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({required this.label, required this.value, required this.color, this.large = false});
  final String label;
  final String value;
  final Color color;
  final bool large;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: large ? 220 : 170,
      height: large ? 130 : 90,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFF161616), Color(0xFF0D0D0D)]),
        border: Border.all(color: color),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16)],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _AnalogDial extends StatelessWidget {
  const _AnalogDial();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(colors: [_kGreen, Colors.yellow, _kRed, _kGreen]),
        boxShadow: const [BoxShadow(color: Colors.cyanAccent, blurRadius: 18)],
      ),
      child: Center(
        child: Container(
          width: 186,
          height: 186,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: _kBg),
          child: const Center(child: Text('ANALOG', style: TextStyle(color: _kBlue))),
        ),
      ),
    );
  }
}

Widget _smallBlock(String label, String value, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white24),
    ),
    child: Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.8))),
        Text(value, style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _telemetryStat(String k, String v) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 6),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kGreen.withValues(alpha: 0.8)),
    ),
    child: Column(
      children: [
        Text(k, style: const TextStyle(color: _kGreen)),
        const SizedBox(height: 4),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
