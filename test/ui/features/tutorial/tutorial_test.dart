import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zakerly/l10n/strings.dart';
import 'package:zakerly/ui/features/tutorial/tutorial.dart';
import 'package:zakerly/ui/features/tutorial/tutorial_copy.dart';
import 'package:zakerly/ui/features/tutorial/tutorial_targets.dart';
import 'package:zakerly/ui/theme.dart';

/// A harness with two real, sized, on-screen widgets wearing the first two
/// tutorial keys, plus buttons to trigger the two public entry points. The
/// rest of the keys are never mounted, so the tour should only ever show
/// these two steps.
Widget _harness() {
  return MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Builder(
      builder: (context) => Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () => maybeShowTutorial(context),
              child: const Text('maybe'),
            ),
            ElevatedButton(
              onPressed: () => showTutorial(context),
              child: const Text('replay'),
            ),
            Container(key: TutorialTargets.sync, width: 40, height: 40, color: Colors.blue),
            Container(key: TutorialTargets.courses, width: 40, height: 40, color: Colors.red),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows once automatically, then only via explicit replay', (tester) async {
    await tester.pumpWidget(_harness());

    // First automatic trigger: not seen yet, so it shows (after its
    // internal frame + settle delay).
    await tester.tap(find.text('maybe'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps.first.title), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps.first.title), findsNothing);

    // Second automatic trigger: already seen, so it's a no-op.
    await tester.tap(find.text('maybe'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps.first.title), findsNothing);

    // Explicit replay (e.g. from Settings) always works.
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps.first.title), findsOneWidget);
  });

  testWidgets('Next/Back walk through the mounted steps and show a step count', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();

    // Only two keys are mounted in this harness, so the tour is 1 of 2 / 2
    // of 2, not the full 8-step list.
    expect(find.text(tutorialSteps[0].title), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Back'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps[1].title), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps[0].title), findsOneWidget);
  });

  testWidgets('last step shows Done and closes the tour', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps[1].title), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps[1].title), findsNothing);
  });

  testWidgets('Escape dismisses the tour', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps.first.title), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps.first.title), findsNothing);
  });

  testWidgets('tapping the scrim advances to the next step', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps[0].title), findsOneWidget);

    // Tap somewhere far from the bubble and the lit targets.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps[1].title), findsOneWidget);
  });

  testWidgets('arrow keys still work after clicking Next', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps[1].title), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps[0].title), findsOneWidget);
  });

  testWidgets('skips targets in a hidden IndexedStack child and uses the budget pill fallback',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () => showTutorial(context),
                  child: const Text('replay'),
                ),
                Container(key: TutorialTargets.sync, width: 40, height: 40, color: Colors.blue),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IndexedStack(
                    index: 0,
                    children: [
                      const ColoredBox(color: Colors.green),
                      // Laid out, sized, but never visible.
                      Container(key: TutorialTargets.courses, color: Colors.red),
                    ],
                  ),
                ),
                Container(key: TutorialTargets.budgetPill, width: 40, height: 40, color: Colors.amber),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();

    expect(find.text(tutorialSteps[0].title), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps[1].title), findsNothing);
    expect(find.text(S.en.tutorialBudgetTitle), findsOneWidget);
  });

  testWidgets('a tutorial with no mounted targets is a no-op', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showTutorial(context),
            child: const Text('replay'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();
    expect(find.text(tutorialSteps.first.title), findsNothing);
  });
}
