import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journal_ai/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JournalifeApp());

    // Verify that our app shows the Journalife title.
    expect(find.text('Journalife'), findsOneWidget);

    // Verify that we have a bottom navigation bar with Home and Calendar items.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
  });
}
