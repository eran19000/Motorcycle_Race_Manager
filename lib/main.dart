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
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22D3EE),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF0E0E0E),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF000000),
          indicatorColor: const Color(0x3322D3EE),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF22D3EE));
            }
            return const IconThemeData(color: Colors.white60);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF22D3EE),
                fontWeight: FontWeight.w900,
              );
            }
            return const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w700,
            );
          }),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ).copyWith(
              bodyLarge: const TextStyle(fontWeight: FontWeight.bold),
              bodyMedium: const TextStyle(fontWeight: FontWeight.bold),
              titleLarge: const TextStyle(fontWeight: FontWeight.bold),
              titleMedium: const TextStyle(fontWeight: FontWeight.bold),
              headlineMedium: const TextStyle(fontWeight: FontWeight.bold),
            ),
        chipTheme: const ChipThemeData(
          side: BorderSide(color: Color(0xFF22D3EE), width: 1.0),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111111),
          surfaceTintColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF22D3EE), width: 1.0),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.green.shade700;
            return Colors.grey.shade600;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.green.shade300;
            return Colors.grey.shade300;
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            disabledBackgroundColor: const Color(0xFF3A3A3A),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          helperStyle: const TextStyle(color: Colors.white70),
          labelStyle: const TextStyle(color: Colors.white),
          floatingLabelStyle: const TextStyle(color: Color(0xFF22D3EE)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1.1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1.1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1.4),
          ),
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
          backgroundColor: const Color(0xFF000000),
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
                            color: const Color(0xFF0F0F0F),
                            border: Border.all(color: const Color(0xFF22D3EE), width: 1.2),
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
