import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_context_switcher/app.dart';

void main() {
  testWidgets('DevContextSwitcherApp smoke test - verifies home page loads', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: DevContextSwitcherApp(),
      ),
    );

    // Pump a few frames
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title is present
    expect(find.text('Dev Context Switcher'), findsOneWidget);

    // Verify Navigation destinations are present
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('Capturer'), findsOneWidget);
    expect(find.text('Modèles'), findsOneWidget);
    expect(find.text('Paramètres'), findsOneWidget);
  });
}
