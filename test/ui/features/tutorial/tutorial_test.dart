import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zakerly/ui/features/tutorial/tutorial.dart';
import 'package:zakerly/ui/features/tutorial/tutorial_pages.dart';
import 'package:zakerly/ui/theme.dart';

Widget _harness() {
  return MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Builder(
      builder: (context) => Column(
        children: [
          ElevatedButton(
            onPressed: () => maybeShowTutorial(context),
            child: const Text('maybe'),
          ),
          ElevatedButton(
            onPressed: () => showTutorial(context),
            child: const Text('replay'),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('shows once automatically, then only via explicit replay', (tester) async {
    await tester.pumpWidget(_harness());

    // First automatic trigger: not seen yet, so it shows.
    await tester.tap(find.text('maybe'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Zakerly'), findsOneWidget);
    expect(find.text(tutorialPages.first.headline), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Zakerly'), findsNothing);

    // Second automatic trigger: already seen, so it's a no-op.
    await tester.tap(find.text('maybe'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Zakerly'), findsNothing);

    // Explicit replay (e.g. from Settings) always works.
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Zakerly'), findsOneWidget);
  });

  testWidgets('Next/Back walk through pages and update the dots', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();

    expect(find.text(tutorialPages[0].headline), findsOneWidget);
    expect(find.text('Back'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialPages[1].headline), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialPages[0].headline), findsOneWidget);
  });

  testWidgets('last page shows Get started and closes the sheet', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();

    for (var i = 0; i < tutorialPages.length - 1; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text(tutorialPages.last.headline), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Zakerly'), findsNothing);
  });

  testWidgets('Escape dismisses the tutorial', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Zakerly'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Zakerly'), findsNothing);
  });
}
