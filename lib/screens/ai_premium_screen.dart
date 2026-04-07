import 'package:flutter/material.dart';

class AiPremiumScreen extends StatelessWidget {
  const AiPremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.auto_graph),
          title: Text('AI Line Analysis'),
          subtitle: Text('Compares rider line to ideal racing line and suggests gains.'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.show_chart),
          title: Text('Advanced Telemetry Graphs'),
          subtitle: Text('Acceleration, G-force, braking pressure over distance/time.'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.workspace_premium),
          title: Text('Premium Plan'),
          subtitle: Text('Unlock deeper analytics, coaching prompts, and exports.'),
        ),
      ],
    );
  }
}
