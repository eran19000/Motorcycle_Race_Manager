import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motorcycle_race_manager/main.dart';

void main() {
  testWidgets('RaceManagerApp builds', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const RaceManagerApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
