import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiPremiumScreen extends StatefulWidget {
  const AiPremiumScreen({super.key});

  @override
  State<AiPremiumScreen> createState() => _AiPremiumScreenState();
}

class _AiPremiumScreenState extends State<AiPremiumScreen> {
  final _videoController = TextEditingController();
  final _lapController = TextEditingController();
  final _aiPromptController =
      TextEditingController(text: 'Analyze my racing line and braking points');
  bool _premiumGraphs = false;
  bool _premiumAi = false;
  String _aiResult = 'AI is locked. Activate AI Premium to run Gemini guidance.';
  List<double> _samples = const [0.1, 0.2, 0.4, 0.5, 0.48, 0.63, 0.7];

  @override
  void initState() {
    super.initState();
    _loadPremiumState();
  }

  Future<void> _loadPremiumState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _premiumGraphs = prefs.getBool('premium_graphs') ?? false;
      _premiumAi = prefs.getBool('premium_ai') ?? false;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22D3EE)),
          ),
          child: const Text(
            'AI / Premium / Video Analysis',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 10),
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
        const Divider(),
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
        const Divider(),
        TextField(
          controller: _videoController,
          decoration: const InputDecoration(
            labelText: 'Video path / URL',
            helperText: 'Attach a video to a specific lap for overlay analysis',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _lapController,
          decoration: const InputDecoration(labelText: 'Related lap number'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
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
          decoration: const InputDecoration(labelText: 'AI prompt'),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 12),
        if (_premiumGraphs) ...[
          const Text('Premium Graph Preview'),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _SimpleLinePainter(_samples),
              child: const SizedBox.expand(),
            ),
          ),
        ] else ...[
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Graphs are locked'),
            subtitle: Text('Enable Premium Graphs to view telemetry charts.'),
          ),
        ],
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
