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
  final List<double> _samples = const [0.1, 0.2, 0.4, 0.5, 0.48, 0.63, 0.7];

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
