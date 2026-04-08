import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/racing_tracks.dart';
import '../models/racing_track.dart';
import '../models/rider.dart';

class TelemetrySnapshot {
  TelemetrySnapshot({
    required this.elapsed,
    required this.leanAngleDeg,
    required this.speedKmh,
    required this.maxSpeedKmh,
    required this.currentLap,
    required this.bestLap,
    required this.idealLap,
    required this.useExternalGps,
    required this.personalBestSectorTriggered,
    required this.sessionBestLapTriggered,
    required this.finishLine,
    required this.currentPosition,
    required this.riders,
    required this.selectedTrack,
    required this.demoMode,
    required this.telemetryTrail,
  });

  final Duration elapsed;
  final double leanAngleDeg;
  final double speedKmh;
  final double maxSpeedKmh;
  final int currentLap;
  final Duration bestLap;
  final Duration idealLap;
  final bool useExternalGps;
  final bool personalBestSectorTriggered;
  final bool sessionBestLapTriggered;
  final Position? finishLine;
  final Position? currentPosition;
  final List<RiderLiveData> riders;
  final RacingTrack selectedTrack;
  final bool demoMode;
  final List<TelemetryTrailPoint> telemetryTrail;
}

class TelemetryTrailPoint {
  TelemetryTrailPoint({
    required this.latitude,
    required this.longitude,
    required this.isAcceleration,
  });

  final double latitude;
  final double longitude;
  final bool isAcceleration;
}

class TelemetryService extends ChangeNotifier {
  TelemetryService() {
    selectTrack(_selectedTrack);
    _ticker = Timer.periodic(const Duration(milliseconds: 150), _onTick);
    _init();
  }

  late final Timer _ticker;
  DateTime _sessionStart = DateTime.now();
  DateTime _lapStart = DateTime.now();
  Duration _bestLap = const Duration(hours: 1);
  Duration _idealLap = const Duration(hours: 1);
  final List<Duration> _bestSectors = const [
    Duration(hours: 1),
    Duration(hours: 1),
    Duration(hours: 1),
  ].toList();
  final List<Duration> _currentSectors = [];
  int _currentSector = 0;
  int _lap = 1;
  double _maxSpeed = 0;
  double _speed = 0;
  double _leanAngle = 0;
  bool _useExternalGps = false;
  bool _personalBestSectorTriggered = false;
  bool _sessionBestLapTriggered = false;
  Position? _finishLine;
  Position? _lastPosition;
  bool _finishLineArmed = true;
  RacingTrack _selectedTrack = racingTracks.first;
  bool _demoMode = kIsWeb;
  final List<TelemetryTrailPoint> _telemetryTrail = [];
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _nmeaSub;
  BluetoothDevice? _externalDevice;
  final List<RiderLiveData> _mockRiders = [
    RiderLiveData(
      id: 'r41',
      displayName: 'Rider 41',
      bestLap: const Duration(minutes: 1, seconds: 43, milliseconds: 440),
      positionX: 0.16,
      positionY: 0.42,
      speedGroup: 'B',
      isPersonalBest: true,
    ),
    RiderLiveData(
      id: 'r93',
      displayName: 'Rider 93',
      bestLap: const Duration(minutes: 1, seconds: 42, milliseconds: 180),
      positionX: 0.58,
      positionY: 0.30,
      speedGroup: 'A',
      isSessionBest: true,
    ),
    RiderLiveData(
      id: 'r12',
      displayName: 'Rider 12',
      bestLap: const Duration(minutes: 1, seconds: 45, milliseconds: 260),
      positionX: 0.77,
      positionY: 0.74,
      speedGroup: 'C',
    ),
  ];

  TelemetrySnapshot get snapshot => TelemetrySnapshot(
        elapsed: DateTime.now().difference(_sessionStart),
        leanAngleDeg: _leanAngle,
        speedKmh: _speed,
        maxSpeedKmh: _maxSpeed,
        currentLap: _lap,
        bestLap: _bestLap == const Duration(hours: 1) ? Duration.zero : _bestLap,
        idealLap: _idealLap == const Duration(hours: 1) ? Duration.zero : _idealLap,
        useExternalGps: _useExternalGps,
        personalBestSectorTriggered: _personalBestSectorTriggered,
        sessionBestLapTriggered: _sessionBestLapTriggered,
        finishLine: _finishLine,
        currentPosition: _lastPosition,
        riders: List<RiderLiveData>.unmodifiable(_mockRiders),
        selectedTrack: _selectedTrack,
        demoMode: _demoMode,
        telemetryTrail: List<TelemetryTrailPoint>.unmodifiable(_telemetryTrail),
      );

  Future<void> _init() async {
    _gyroSub = gyroscopeEventStream().listen((event) {
      _leanAngle = (_leanAngle + event.y * 1.4).clamp(-62.0, 62.0);
      notifyListeners();
    });

    final hasPermission = await _requestGpsPermission();
    if (hasPermission) {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        ),
      ).listen((position) {
        final previousSpeed = _speed;
        _lastPosition = position;
        _speed = max(position.speed * 3.6, 0.0);
        _pushTrailPoint(position, _speed - previousSpeed >= 0);
        if (_speed > _maxSpeed) _maxSpeed = _speed;
        _evaluateFinishLineCross(position);
        notifyListeners();
      });
    }
  }

  Future<void> toggleExternalGps(bool value) async {
    _useExternalGps = value;
    if (value) {
      await _startExternalGpsFlow();
    } else {
      await _stopExternalGpsFlow();
    }
    notifyListeners();
  }

  void setFinishLineFromCurrentLocation() {
    if (_lastPosition == null) return;
    _finishLine = _lastPosition;
    _finishLineArmed = true;
    notifyListeners();
  }

  void toggleDemoMode(bool value) {
    _demoMode = value;
    notifyListeners();
  }

  RacingTrack get selectedTrack => _selectedTrack;

  void selectTrack(RacingTrack track) {
    _selectedTrack = track;
    _finishLine = Position(
      latitude: track.finishLat,
      longitude: track.finishLng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _finishLineArmed = true;
    _telemetryTrail.clear();
    notifyListeners();
  }

  String externalGpsProviderLabel() {
    return _useExternalGps && _externalDevice != null
        ? 'External GPS: ${_externalDevice!.platformName}'
        : _useExternalGps
            ? 'External GPS (searching...)'
        : 'Internal GPS';
  }

  void moveRiderToSpeedGroup(String riderId, String speedGroup) {
    final idx = _mockRiders.indexWhere((r) => r.id == riderId);
    if (idx == -1) return;
    _mockRiders[idx] = _mockRiders[idx].copyWith(speedGroup: speedGroup);
    notifyListeners();
  }

  void _onTick(Timer _) {
    if (_demoMode) {
      _simulateTelemetry();
    }
    _simulateRiderMovement();
    _evaluateSectorSplitByLapProgress();
    notifyListeners();
  }

  void _simulateTelemetry() {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _leanAngle = 47 * sin(t * 0.9);
    _speed = 155 + 42 * sin(t * 0.6) + 18 * sin(t * 1.6);
    if (_speed > _maxSpeed) {
      _maxSpeed = _speed;
    }
    final lat = _selectedTrack.finishLat + 0.00028 * cos(t * 0.12);
    final lng = _selectedTrack.finishLng + 0.00035 * sin(t * 0.12);
    _lastPosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 4,
      altitude: 0,
      heading: 0,
      speed: _speed / 3.6,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _pushTrailPoint(_lastPosition!, _speed >= 150);
    _evaluateFinishLineCross(_lastPosition!);
  }

  void _pushTrailPoint(Position position, bool isAcceleration) {
    _telemetryTrail.add(
      TelemetryTrailPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        isAcceleration: isAcceleration,
      ),
    );
    if (_telemetryTrail.length > 240) {
      _telemetryTrail.removeAt(0);
    }
  }

  void _evaluateSectorSplitByLapProgress() {
    final lapElapsed = DateTime.now().difference(_lapStart);
    final splitTargets = <Duration>[
      const Duration(seconds: 28),
      const Duration(seconds: 58),
      const Duration(seconds: 88),
    ];

    while (_currentSector < splitTargets.length &&
        lapElapsed >= splitTargets[_currentSector]) {
      final sectorStartMs = _currentSector == 0
          ? 0
          : splitTargets[_currentSector - 1].inMilliseconds;
      final sectorDuration =
          Duration(milliseconds: lapElapsed.inMilliseconds - sectorStartMs);
      _registerSector(_currentSector, sectorDuration);
      _currentSector += 1;
    }
  }

  void _registerSector(int sectorIndex, Duration sectorDuration) {
    if (_currentSectors.length <= sectorIndex) {
      _currentSectors.add(sectorDuration);
    }
    if (sectorDuration < _bestSectors[sectorIndex]) {
      _bestSectors[sectorIndex] = sectorDuration;
      _personalBestSectorTriggered = true;
      Timer(const Duration(seconds: 3), () {
        _personalBestSectorTriggered = false;
        notifyListeners();
      });
    }
    _idealLap = _bestSectors.fold(Duration.zero, (sum, item) => sum + item);
  }

  void _evaluateFinishLineCross(Position currentPosition) {
    final finishLine = _finishLine;
    if (finishLine == null) return;
    final distanceFromFinish = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      finishLine.latitude,
      finishLine.longitude,
    );

    if (distanceFromFinish > 25) {
      _finishLineArmed = true;
    }
    if (_finishLineArmed && distanceFromFinish < 10 && _speed > 20) {
      _finishLineArmed = false;
      _startNextLap();
    }
  }

  void _startNextLap() {
    final lapTime = DateTime.now().difference(_lapStart);
    if (lapTime <= const Duration(seconds: 15)) return;
    if (lapTime < _bestLap) {
      _bestLap = lapTime;
      _sessionBestLapTriggered = true;
      final flashTimer = Timer.periodic(const Duration(milliseconds: 260), (timer) {
        _sessionBestLapTriggered = !_sessionBestLapTriggered;
        notifyListeners();
      });
      Timer(const Duration(seconds: 2), () {
        flashTimer.cancel();
        _sessionBestLapTriggered = false;
        // Best-lap flash period ends after green blink sequence.
        notifyListeners();
      });
    }
    _pushLapToDatabase(lapTime: lapTime, maxSpeedKmh: _maxSpeed);
    _lap += 1;
    _lapStart = DateTime.now();
    _currentSector = 0;
    _currentSectors.clear();
  }

  void _simulateRiderMovement() {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (var i = 0; i < _mockRiders.length; i++) {
      final rider = _mockRiders[i];
      final x = 0.5 + 0.35 * sin(t * 0.22 + i);
      final y = 0.5 + 0.30 * cos(t * 0.27 + i * 1.3);
      _mockRiders[i] = RiderLiveData(
        id: rider.id,
        displayName: rider.displayName,
        bestLap: rider.bestLap,
        positionX: x.clamp(0.05, 0.95),
        positionY: y.clamp(0.05, 0.95),
        speedGroup: rider.speedGroup,
        isSessionBest: rider.isSessionBest,
        isPersonalBest: rider.isPersonalBest,
      );
    }
  }

  Future<bool> _requestGpsPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _pushLapToDatabase({
    required Duration lapTime,
    required double maxSpeedKmh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('admin_live_laps') ?? '[]';
    final parsed = (jsonDecode(raw) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    parsed.insert(0, {
      'ts': DateTime.now().toIso8601String(),
      'track': _selectedTrack.name,
      'lapMs': lapTime.inMilliseconds,
      'maxSpeedKmh': maxSpeedKmh,
    });
    if (parsed.length > 200) {
      parsed.removeRange(200, parsed.length);
    }
    await prefs.setString('admin_live_laps', jsonEncode(parsed));
  }

  Future<void> _startExternalGpsFlow() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      if (_externalDevice != null) return;
      for (final item in results) {
        final name = item.device.platformName.toLowerCase();
        if (name.contains('racebox') || name.contains('gps')) {
          _externalDevice = item.device;
          await FlutterBluePlus.stopScan();
          await _externalDevice?.connect(timeout: const Duration(seconds: 5));
          // Placeholder NMEA high-frequency stream simulation from BLE bytes.
          _nmeaSub = Stream<List<int>>.periodic(
            const Duration(milliseconds: 100),
            (i) => utf8.encode('\$GPRMC,${i % 60},A,,,,,,${(_speed / 1.852).toStringAsFixed(1)},,,,*00'),
          ).listen(_parseNmeaPayload);
          notifyListeners();
          break;
        }
      }
    });
  }

  Future<void> _stopExternalGpsFlow() async {
    await _scanSub?.cancel();
    await _nmeaSub?.cancel();
    try {
      await _externalDevice?.disconnect();
    } catch (_) {}
    _externalDevice = null;
  }

  void _parseNmeaPayload(List<int> bytes) {
    final sentence = utf8.decode(bytes, allowMalformed: true);
    if (!sentence.contains('GPRMC')) return;
    // Placeholder: when external stream is active we bias updates as high-frequency source.
    _speed = max(_speed, 22);
    notifyListeners();
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _positionSub?.cancel();
    _scanSub?.cancel();
    _nmeaSub?.cancel();
    _ticker.cancel();
    super.dispose();
  }
}
