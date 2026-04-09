import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class TelemetryDb {
  TelemetryDb._();
  static final TelemetryDb instance = TelemetryDb._();

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final base = await getDatabasesPath();
    final dbPath = p.join(base, 'neon_race_telemetry.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE lap_points(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts_ms INTEGER NOT NULL,
            lap_no INTEGER NOT NULL,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            speed_kmh REAL NOT NULL,
            g_force REAL NOT NULL,
            lean_deg REAL NOT NULL
          );
        ''');
      },
    );
    return _db!;
  }

  Future<void> insertPoint(TelemetryPoint point) async {
    final db = await _open();
    await db.insert('lap_points', {
      'ts_ms': point.tsMs,
      'lap_no': point.lapNo,
      'lat': point.lat,
      'lng': point.lng,
      'speed_kmh': point.speedKmh,
      'g_force': point.gForce,
      'lean_deg': point.leanDeg,
    });
  }

  Future<List<int>> laps() async {
    final db = await _open();
    final rows = await db.rawQuery(
      'SELECT lap_no FROM lap_points GROUP BY lap_no ORDER BY lap_no DESC',
    );
    return rows
        .map((e) => (e['lap_no'] as num?)?.toInt())
        .whereType<int>()
        .toList();
  }

  Future<List<TelemetryPoint>> pointsForLap(int lapNo) async {
    final db = await _open();
    final rows = await db.query(
      'lap_points',
      where: 'lap_no = ?',
      whereArgs: [lapNo],
      orderBy: 'ts_ms ASC',
    );
    return rows
        .map(
          (r) => TelemetryPoint(
            tsMs: (r['ts_ms'] as num).toInt(),
            lapNo: (r['lap_no'] as num).toInt(),
            lat: (r['lat'] as num).toDouble(),
            lng: (r['lng'] as num).toDouble(),
            speedKmh: (r['speed_kmh'] as num).toDouble(),
            gForce: (r['g_force'] as num).toDouble(),
            leanDeg: (r['lean_deg'] as num).toDouble(),
          ),
        )
        .toList();
  }
}
