import 'package:flutter/material.dart';

import 'screens/home_shell.dart';

void main() {
  runApp(const RaceManagerApp());
}

class RaceManagerApp extends StatelessWidget {
  const RaceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moto Race Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey.shade100,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ).copyWith(
              bodyLarge: const TextStyle(fontWeight: FontWeight.bold),
              bodyMedium: const TextStyle(fontWeight: FontWeight.bold),
              titleLarge: const TextStyle(fontWeight: FontWeight.bold),
              titleMedium: const TextStyle(fontWeight: FontWeight.bold),
              headlineMedium: const TextStyle(fontWeight: FontWeight.bold),
            ),
        chipTheme: const ChipThemeData(
          side: BorderSide(color: Colors.black, width: 1.3),
        ),
      ),
      home: const _MobilePreviewFrame(child: HomeShell()),
    );
  }
}

class _MobilePreviewFrame extends StatefulWidget {
  const _MobilePreviewFrame({required this.child});

  final Widget child;

  @override
  State<_MobilePreviewFrame> createState() => _MobilePreviewFrameState();
}

class _MobilePreviewFrameState extends State<_MobilePreviewFrame> {
  bool _forcePhoneFrame = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canUseFrame = constraints.maxWidth > 500;
        final useFrame = canUseFrame && _forcePhoneFrame;
        if (!canUseFrame) return widget.child;
        return Scaffold(
          backgroundColor: Colors.grey.shade300,
          body: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Phone Frame')),
                      ButtonSegment(value: false, label: Text('Full Width')),
                    ],
                    selected: {_forcePhoneFrame},
                    onSelectionChanged: (selection) {
                      setState(() => _forcePhoneFrame = selection.first);
                    },
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: useFrame
                      ? Container(
                          width: 412,
                          height: 860,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 16,
                                color: Colors.black26,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.child,
                        )
                      : widget.child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
