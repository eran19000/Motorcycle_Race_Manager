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
import '../widgets/time_formatters.dart';

class TelemetrySnapshot {
  TelemetrySnapshot({
    required this.elapsed,
    required this.lapElapsed,
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
    required this.gForce,
    required this.gyroAlive,
    required this.accelerometerAlive,
    required this.internalGpsAlive,
    required this.externalGpsAlive,
    required this.sectorUpdateMessage,
    required this.bestSectorTimesMs,
    required this.sessionPeakLeanAbsDeg,
  });

  final Duration elapsed;
  /// Time since the current lap started (lap timer).
  final Duration lapElapsed;
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
  final double gForce;
  final bool gyroAlive;
  final bool accelerometerAlive;
  final bool internalGpsAlive;
  final bool externalGpsAlive;
  /// Non-null briefly after a GPS sector split (S1/S2/S3) for dashboard UI.
  final String? sectorUpdateMessage;
  /// Best sector durations this session (ms); 0 = no valid split yet for that index.
  final List<int> bestSectorTimesMs;
  /// Maximum absolute lean magnitude seen this session (deg), for coaching summaries.
  final double sessionPeakLeanAbsDeg;
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
  final DateTime _sessionStart = DateTime.now();
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
  double _gForce = 0;
  double _leanAngle = 0;
  double _sessionPeakLeanAbs = 0;
  bool _useExternalGps = false;
  bool _personalBestSectorTriggered = false;
  bool _sessionBestLapTriggered = false;
  Position? _finishLine;
  Position? _lastPosition;
  bool _finishLineArmed = true;
  static const double _sectorTriggerRadiusM = 15;
  static const double _minSpeedKmhForSector = 15;
  bool _gpsSector1Armed = true;
  bool _gpsSector2Armed = false;
  DateTime? _timeAtSector1Split;
  String? _sectorUpdateMessage;
  Timer? _sectorUpdateClearTimer;
  RacingTrack _selectedTrack = racingTracks.first;
  bool _demoMode = kIsWeb;
  final List<TelemetryTrailPoint> _telemetryTrail = [];
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _nmeaSub;
  BluetoothDevice? _externalDevice;
  DateTime? _lastGpsUpdateAt;
  DateTime? _lastGyroAt;
  DateTime? _lastAccAt;
  DateTime? _lastNmeaAt;
  final List<Duration> _sectorSplitTargets = [
    const Duration(seconds: 28),
    const Duration(seconds: 58),
    const Duration(seconds: 88),
  ];
  final List<RiderLiveData> _mockRiders = [
    RiderLiveData(
      id: 'r41',
      displayName: 'Rider 41',
      bestLap: const Duration(minutes: 1, seconds: 43, milliseconds: 440),
      lastLap: const Duration(minutes: 1, seconds: 44, milliseconds: 210),
      sectors: const [
        Duration(seconds: 33, milliseconds: 120),
        Duration(seconds: 35, milliseconds: 400),
        Duration(seconds: 35, milliseconds: 690),
      ],
      maxSpeedKmh: 243.2,
      positionX: 0.16,
      positionY: 0.42,
      speedGroup: 'B',
      isPersonalBest: true,
    ),
    RiderLiveData(
      id: 'r93',
      displayName: 'Rider 93',
      bestLap: const Duration(minutes: 1, seconds: 42, milliseconds: 180),
      lastLap: const Duration(minutes: 1, seconds: 42, milliseconds: 880),
      sectors: const [
        Duration(seconds: 32, milliseconds: 540),
        Duration(seconds: 34, milliseconds: 820),
        Duration(seconds: 35, milliseconds: 520),
      ],
      maxSpeedKmh: 247.4,
      positionX: 0.58,
      positionY: 0.30,
      speedGroup: 'A',
      isSessionBest: true,
    ),
    RiderLiveData(
      id: 'r12',
      displayName: 'Rider 12',
      bestLap: const Duration(minutes: 1, seconds: 45, milliseconds: 260),
      lastLap: const Duration(minutes: 1, seconds: 46, milliseconds: 730),
      sectors: const [
        Duration(seconds: 34, milliseconds: 210),
        Duration(seconds: 36, milliseconds: 460),
        Duration(seconds: 36, milliseconds: 60),
      ],
      maxSpeedKmh: 236.8,
      positionX: 0.77,
      positionY: 0.74,
      speedGroup: 'C',
    ),
  ];

  TelemetrySnapshot get snapshot => TelemetrySnapshot(
        elapsed: DateTime.now().difference(_sessionStart),
        lapElapsed: DateTime.now().difference(_lapStart),
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
        gForce: _gForce,
        gyroAlive: _isFresh(_lastGyroAt, const Duration(seconds: 2)),
        accelerometerAlive: _isFresh(_lastAccAt, const Duration(seconds: 2)),
        internalGpsAlive:
            _demoMode || _isFresh(_lastGpsUpdateAt, const Duration(seconds: 4)),
        externalGpsAlive: !_useExternalGps ||
            (_externalDevice != null &&
                _isFresh(_lastNmeaAt, const Duration(seconds: 2))),
        sectorUpdateMessage: _sectorUpdateMessage,
        bestSectorTimesMs: _bestSectorTimesMsSnapshot(),
        sessionPeakLeanAbsDeg: _sessionPeakLeanAbs,
      );

  List<int> _bestSectorTimesMsSnapshot() {
    const sentinel = Duration(hours: 1);
    return List<int>.generate(3, (i) {
      if (i >= _bestSectors.length) return 0;
      final d = _bestSectors[i];
      if (d >= sentinel) return 0;
      return d.inMilliseconds;
    }, growable: false);
  }

  bool _isFresh(DateTime? ts, Duration threshold) {
    if (ts == null) return false;
    return DateTime.now().difference(ts) <= threshold;
  }

  Future<void> _init() async {
    _gyroSub = gyroscopeEventStream().listen((event) {
      _lastGyroAt = DateTime.now();
      _leanAngle = (_leanAngle + event.y * 1.4).clamp(-62.0, 62.0);
      final a = _leanAngle.abs();
      if (a > _sessionPeakLeanAbs) _sessionPeakLeanAbs = a;
      notifyListeners();
    });
    _accSub = accelerometerEventStream().listen((event) {
      _lastAccAt = DateTime.now();
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      _gForce = (magnitude / 9.80665).clamp(0.0, 4.0);
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
        final now = DateTime.now();
        final speedFromSensor = position.speed * 3.6;
        double computedSpeed = max(speedFromSensor, 0.0);
        if (_lastPosition != null && _lastGpsUpdateAt != null) {
          final dtMs = now.difference(_lastGpsUpdateAt!).inMilliseconds;
          if (dtMs > 0 && computedSpeed < 2) {
            final dM = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            computedSpeed = (dM / (dtMs / 1000.0)) * 3.6;
          }
        }
        _lastGpsUpdateAt = now;
        _lastPosition = position;
        _speed = max(computedSpeed, 0.0);
        _pushTrailPoint(position, _speed - previousSpeed >= 0);
        if (_speed > _maxSpeed) _maxSpeed = _speed;
        _evaluateGpsSectorBeacons(position);
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
    _finishLine = _lastPosition ??
        Position(
          latitude: _selectedTrack.finishLat,
          longitude: _selectedTrack.finishLng,
          timestamp: DateTime.now(),
          accuracy: 6,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
    _finishLineArmed = true;
    notifyListeners();
  }

  List<Duration> get sectorSplitTargets => List<Duration>.from(_sectorSplitTargets);

  void setSectorSplitTargets(List<Duration> cumulativeTargets) {
    if (cumulativeTargets.length != 3) return;
    _sectorSplitTargets
      ..clear()
      ..addAll(cumulativeTargets);
    _currentSector = 0;
    _currentSectors.clear();
    notifyListeners();
  }

  void toggleDemoMode(bool value) {
    _demoMode = value;
    notifyListeners();
  }

  RacingTrack get selectedTrack => _selectedTrack;

  void selectTrack(RacingTrack track) {
    _selectedTrack = track;
    _resetGpsSectorArmsForLap();
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
    final useGpsSectors =
        _selectedTrack.hasGpsSectorBeacons && !_demoMode;
    if (!useGpsSectors) {
      _evaluateSectorSplitByLapProgress();
    }
    notifyListeners();
  }

  void _simulateTelemetry() {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _lastGyroAt = DateTime.now();
    _lastAccAt = DateTime.now();
    _lastGpsUpdateAt = DateTime.now();
    _leanAngle = 47 * sin(t * 0.9);
    final simLeanAbs = _leanAngle.abs();
    if (simLeanAbs > _sessionPeakLeanAbs) _sessionPeakLeanAbs = simLeanAbs;
    _speed = 155 + 42 * sin(t * 0.6) + 18 * sin(t * 1.6);
    _gForce = (1.1 + 0.9 * sin(t * 2.0)).clamp(0.0, 4.0);
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
    _evaluateGpsSectorBeacons(_lastPosition!);
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
    final splitTargets = _sectorSplitTargets;

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

  void _resetGpsSectorArmsForLap() {
    _gpsSector1Armed = true;
    _gpsSector2Armed = false;
    _timeAtSector1Split = null;
  }

  void _flashSectorUpdate(String message) {
    _sectorUpdateMessage = message;
    notifyListeners();
    _sectorUpdateClearTimer?.cancel();
    _sectorUpdateClearTimer = Timer(const Duration(milliseconds: 2600), () {
      _sectorUpdateMessage = null;
      notifyListeners();
    });
  }

  void _evaluateGpsSectorBeacons(Position currentPosition) {
    final track = _selectedTrack;
    if (!track.hasGpsSectorBeacons || _demoMode) return;

    final lat = currentPosition.latitude;
    final lng = currentPosition.longitude;
    final s1Lat = track.sector1Lat!;
    final s1Lng = track.sector1Lng!;
    final s2Lat = track.sector2Lat!;
    final s2Lng = track.sector2Lng!;

    if (_gpsSector1Armed) {
      final d1 = Geolocator.distanceBetween(lat, lng, s1Lat, s1Lng);
      if (d1 <= _sectorTriggerRadiusM && _speed > _minSpeedKmhForSector) {
        final dur = DateTime.now().difference(_lapStart);
        _registerSector(0, dur);
        _flashSectorUpdate(
          'SECTOR UPDATE — S1 ${formatDuration(dur, precision: TimerPrecision.centisecond)}',
        );
        _gpsSector1Armed = false;
        _gpsSector2Armed = true;
        _timeAtSector1Split = DateTime.now();
      }
    }

    if (_gpsSector2Armed) {
      final d2 = Geolocator.distanceBetween(lat, lng, s2Lat, s2Lng);
      if (d2 <= _sectorTriggerRadiusM && _speed > _minSpeedKmhForSector) {
        final from = _timeAtSector1Split ?? _lapStart;
        final dur = DateTime.now().difference(from);
        _registerSector(1, dur);
        _flashSectorUpdate(
          'SECTOR UPDATE — S2 ${formatDuration(dur, precision: TimerPrecision.centisecond)}',
        );
        _gpsSector2Armed = false;
      }
    }
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

    final useGpsSectors =
        _selectedTrack.hasGpsSectorBeacons && !_demoMode;
    if (useGpsSectors && _currentSectors.length >= 2) {
      final s3 = lapTime - _currentSectors[0] - _currentSectors[1];
      if (s3 >= Duration.zero) {
        _registerSector(2, s3);
        _flashSectorUpdate(
          'SECTOR UPDATE — S3 ${formatDuration(s3, precision: TimerPrecision.centisecond)}',
        );
      }
    }

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
    _resetGpsSectorArmsForLap();
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
        lastLap: rider.lastLap,
        sectors: rider.sectors,
        maxSpeedKmh: rider.maxSpeedKmh,
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
          await _externalDevice?.connect(
            license: License.free,
            timeout: const Duration(seconds: 5),
          );
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
    _lastNmeaAt = DateTime.now();
    // Placeholder: when external stream is active we bias updates as high-frequency source.
    _speed = max(_speed, 22 + (_gForce * 5));
    notifyListeners();
  }

  @override
  void dispose() {
    _sectorUpdateClearTimer?.cancel();
    _gyroSub?.cancel();
    _accSub?.cancel();
    _positionSub?.cancel();
    _scanSub?.cancel();
    _nmeaSub?.cancel();
    _ticker.cancel();
    super.dispose();
  }
}
