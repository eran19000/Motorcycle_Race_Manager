import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_api_resolver.dart';
import '../models/racing_track.dart';
import 'telemetry_service.dart';

/// Calls Google Gemini with structured session telemetry for coaching text.
class GeminiCoachingService {
  GeminiCoachingService._();

  static const String _modelName = 'gemini-1.5-flash';

  static Future<String> fetchCoachInsights({
    required TelemetrySnapshot snapshot,
    String? extraUserNotes,
  }) async {
    final apiKey = await GeminiApiResolver.resolve();
    if (apiKey.isEmpty) {
      return 'No Gemini API key configured. Add one in AI / Analysis (saved on device) '
          'or build with --dart-define=GEMINI_API_KEY=your_key.';
    }

    final track = snapshot.selectedTrack;
    final sectors = snapshot.bestSectorTimesMs;
    final sectorLines = <String>[];
    for (var i = 0; i < sectors.length; i++) {
      final ms = sectors[i];
      if (ms <= 0) {
        sectorLines.add('S${i + 1}: (no split recorded this session)');
      } else {
        final s = (ms / 1000).toStringAsFixed(2);
        sectorLines.add('S${i + 1}: ${s}s');
      }
    }

    final focusHint = _trackCoachingHint(track);

    final dataBlock = StringBuffer()
      ..writeln('Track: ${track.name} (${track.city}, ${track.countryCode})')
      ..writeln('Track id: ${track.id}')
      ..writeln('Circuit length (reference): ${track.lengthKm} km')
      ..writeln('Best lap (session): ${_fmtMs(snapshot.bestLap.inMilliseconds)}')
      ..writeln('Ideal lap (best sectors summed): ${_fmtMs(snapshot.idealLap.inMilliseconds)}')
      ..writeln('Max speed (session): ${snapshot.maxSpeedKmh.toStringAsFixed(1)} km/h')
      ..writeln('Peak lean magnitude (session, estimated): ${snapshot.sessionPeakLeanAbsDeg.toStringAsFixed(1)}°')
      ..writeln('Sector / split times (best recorded this session):')
      ..writeln(sectorLines.join('\n'));

    if (extraUserNotes != null && extraUserNotes.trim().isNotEmpty) {
      dataBlock.writeln('Rider notes: ${extraUserNotes.trim()}');
    }

    final prompt = '''
You are an expert motorcycle circuit coach. The rider wants concise, actionable feedback.

$focusHint

Here is telemetry summary from their lap timer app (not a full data logger — treat as indicative):

$dataBlock

Respond with clear sections:
1) Overall assessment (2–4 sentences)
2) 3–5 bullet tips to improve lap time or consistency (reference sectors or track features when relevant)
3) One safety reminder if lean or speed suggests aggressive riding

Keep the tone supportive and practical. Do not invent exact GPS traces; base advice on the numbers given.
''';

    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.65,
        maxOutputTokens: 1024,
      ),
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return 'Gemini returned an empty response. Try again or check your API key and quota.';
      }
      return text;
    } catch (e) {
      return 'Gemini request failed: $e';
    }
  }

  static String _fmtMs(int ms) {
    if (ms <= 0) return '—';
    final totalSec = ms / 1000.0;
    final m = totalSec ~/ 60;
    final s = totalSec - m * 60;
    return '${m}m ${s.toStringAsFixed(2)}s';
  }

  static String _trackCoachingHint(RacingTrack track) {
    final id = track.id.toLowerCase();
    if (id == 'serres') {
      return 'Context: Serres Racing Circuit (Greece) — blend technical sectors with strong braking references; '
          'mention sector rhythm if split times are uneven.';
    }
    if (id == 'arad_track') {
      return 'Context: Arad circuit (Israel) — often wind-affected and traction-limited; comment on consistency '
          'and throttle connection if sectors vary.';
    }
    return 'Context: general circuit riding — relate advice to the stated sector times and speeds when possible.';
  }
}
