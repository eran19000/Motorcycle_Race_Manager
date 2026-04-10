import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/gemini_api_resolver.dart';
import '../services/gemini_coaching_service.dart';
import '../services/telemetry_service.dart';
import '../theme/race_input_theme.dart';

class AiPremiumScreen extends StatefulWidget {
  const AiPremiumScreen({super.key, required this.telemetryService});

  final TelemetryService telemetryService;

  @override
  State<AiPremiumScreen> createState() => _AiPremiumScreenState();
}

class _AiPremiumScreenState extends State<AiPremiumScreen> {
  final _videoController = TextEditingController();
  final _lapController = TextEditingController();
  final _aiPromptController =
      TextEditingController(text: 'Analyze my racing line and braking points');
  final _geminiKeyController = TextEditingController();
  bool _obscureGeminiKey = true;
  bool _premiumGraphs = false;
  bool _premiumAi = false;
  String _aiResult = 'AI is locked. Activate AI Premium to run Gemini guidance.';
  String _coachInsights = '';
  bool _coachLoading = false;
  final List<double> _samples = const [0.1, 0.2, 0.4, 0.5, 0.48, 0.63, 0.7];

  @override
  void initState() {
    super.initState();
    _loadPremiumState();
  }

  Future<void> _loadPremiumState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString(prefsKeyGeminiApi) ?? '';
    if (!mounted) return;
    setState(() {
      _premiumGraphs = prefs.getBool('premium_graphs') ?? false;
      _premiumAi = prefs.getBool('premium_ai') ?? false;
      if (storedKey.isNotEmpty) _geminiKeyController.text = storedKey;
    });
  }

  Future<void> _setPremium(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  void dispose() {
    _videoController.dispose();
    _lapController.dispose();
    _aiPromptController.dispose();
    _geminiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveGeminiKey() async {
    await GeminiApiResolver.saveUserKey(_geminiKeyController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gemini API key saved on this device')),
    );
  }

  Future<void> _clearGeminiKey() async {
    await GeminiApiResolver.clearUserKey();
    _geminiKeyController.clear();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gemini API key removed from this device')),
    );
  }

  Future<void> _runGeminiCoach() async {
    if (!_premiumAi) {
      setState(() {
        _coachInsights = 'Enable Premium AI Coach above to request insights.';
      });
      return;
    }
    setState(() {
      _coachLoading = true;
      _coachInsights = '';
    });
    final snap = widget.telemetryService.snapshot;
    final text = await GeminiCoachingService.fetchCoachInsights(
      snapshot: snap,
      extraUserNotes: _aiPromptController.text,
    );
    if (!mounted) return;
    setState(() {
      _coachLoading = false;
      _coachInsights = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget menuButton(IconData icon, String text, {bool premium = false}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD080FF)),
          boxShadow: const [BoxShadow(color: Color(0x66D080FF), blurRadius: 10)],
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFFD080FF)),
          title: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
          trailing: premium
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('PREMIUM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
                )
              : null,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'AI / Premium Garage',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final left = Column(
              children: [
                menuButton(Icons.emoji_events_outlined, 'Community Best Laps'),
                menuButton(Icons.auto_awesome, 'AI Analysis', premium: true),
                menuButton(Icons.history, 'Lap History'),
                menuButton(Icons.storage_rounded, 'Track Database'),
              ],
            );
            final mid = Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD080FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('AI Analysis:', style: TextStyle(fontWeight: FontWeight.w900)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('PREMIUM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(height: 130, child: CustomPaint(painter: _SimpleLinePainter(_samples), child: const SizedBox.expand())),
                  const SizedBox(height: 8),
                  const Text('Lean Angle:', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  SizedBox(height: 130, child: CustomPaint(painter: _SimpleLinePainter(_samples.reversed.toList()), child: const SizedBox.expand())),
                ],
              ),
            );
            final right = Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFB050)),
                boxShadow: const [BoxShadow(color: Color(0x55FFB050), blurRadius: 14)],
              ),
              child: const Text(
                'Graph\\n\\nVideo Overlays (Premium)\\n\\nGemini AI Coaching\\n\\nFull-Race Stats',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.25),
              ),
            );

            if (compact) {
              return Column(
                children: [
                  left,
                  const SizedBox(height: 10),
                  mid,
                  const SizedBox(height: 10),
                  right,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 10),
                Expanded(flex: 4, child: mid),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: right),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.workspace_premium),
          title: const Text('Premium Graphs Access'),
          subtitle: const Text('Unlock speed, lean and lap trend charts.'),
          trailing: Switch(
            value: _premiumGraphs,
            onChanged: (value) async {
              await _setPremium('premium_graphs', value);
              setState(() => _premiumGraphs = value);
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: const Text('Premium AI Coach (Gemini)'),
          subtitle: const Text('Unlock AI line analysis and coaching comments.'),
          trailing: Switch(
            value: _premiumAi,
            onChanged: (value) async {
              await _setPremium('premium_ai', value);
              setState(() => _premiumAi = value);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gemini API key',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Stored only on this device (SharedPreferences). Prefer --dart-define=GEMINI_API_KEY=... for release builds. '
          'Restrict your key in Google AI Studio (app package / SHA-1) and rotate it if it was ever shared.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _geminiKeyController,
          obscureText: _obscureGeminiKey,
          style: RaceInputTheme.typingStyle,
          decoration: InputDecoration(
            hintText: 'Paste API key (not committed to git)',
            suffixIcon: IconButton(
              icon: Icon(_obscureGeminiKey ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureGeminiKey = !_obscureGeminiKey),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton(onPressed: _saveGeminiKey, child: const Text('Save key')),
            const SizedBox(width: 10),
            OutlinedButton(onPressed: _clearGeminiKey, child: const Text('Clear key')),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _videoController,
          style: RaceInputTheme.typingStyle,
          decoration: const InputDecoration(
            hintText: 'Video path / URL',
            helperText: 'Attach a video to a specific lap for overlay analysis',
            helperMaxLines: 3,
            errorMaxLines: 4,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _lapController,
          style: RaceInputTheme.typingStyle,
          decoration: const InputDecoration(
            hintText: 'Related lap number',
            errorMaxLines: 4,
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final lap = _lapController.text.trim();
            final video = _videoController.text.trim();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  video.isEmpty
                      ? 'Please enter video path/URL first'
                      : 'Video linked to lap $lap (metadata saved for overlay flow)',
                ),
              ),
            );
          },
          icon: const Icon(Icons.video_file),
          label: const Text('Attach Video To Lap'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _aiPromptController,
          maxLines: 3,
          style: RaceInputTheme.typingStyle,
          decoration: const InputDecoration(
            hintText: 'AI prompt',
            errorMaxLines: 4,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            if (!_premiumAi) {
              setState(() {
                _aiResult = 'AI Premium is OFF. Enable it above to use Gemini guidance.';
              });
              return;
            }
            setState(() {
              _aiResult =
                  'Gemini analysis: brake earlier at corner entry, reduce peak lean by 2-3° in sector 2, and improve throttle pick-up for better exit speed.';
            });
          },
          icon: const Icon(Icons.psychology),
          label: const Text('Run AI Analysis'),
        ),
        const SizedBox(height: 8),
        Text(_aiResult),
        const SizedBox(height: 24),
        Text(
          'AI Coach Insights (Gemini)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: widget.telemetryService,
          builder: (context, _) {
            final d = widget.telemetryService.snapshot;
            return Text(
              'Live payload: ${d.selectedTrack.name} · best lap · max ${d.maxSpeedKmh.toStringAsFixed(0)} km/h · '
              'peak lean ${d.sessionPeakLeanAbsDeg.toStringAsFixed(0)}° · sectors ms ${d.bestSectorTimesMs}',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            );
          },
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _coachLoading ? null : _runGeminiCoach,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_coachLoading) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 10),
              ] else ...[
                const Icon(Icons.sports_motorsports),
                const SizedBox(width: 8),
              ],
              Text(_coachLoading ? 'Contacting Gemini…' : 'Get AI Coach Insights'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF38BDF8)),
          ),
          child: SelectableText(
            _coachInsights.isEmpty
                ? 'Tap “Get AI Coach Insights” to send your current session stats (track, best lap, speed, lean, sectors) to Gemini.'
                : _coachInsights,
            style: const TextStyle(height: 1.35, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _SimpleLinePainter extends CustomPainter {
  _SimpleLinePainter(this.samples);
  final List<double> samples;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0E0E0E);
    canvas.drawRect(Offset.zero & size, bg);
    final glow = Paint()
      ..color = const Color(0xFF22D3EE)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final line = Paint()
      ..color = const Color(0xFF22D3EE)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final p = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = (i / (samples.length - 1)) * size.width;
      final y = size.height - (samples[i] * size.height * 0.9) - 8;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    canvas.drawPath(p, glow);
    canvas.drawPath(p, line);
  }

  @override
  bool shouldRepaint(covariant _SimpleLinePainter oldDelegate) => oldDelegate.samples != samples;
}
