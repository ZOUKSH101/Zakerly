// Public API for the first-run tutorial feature. See CONTRACT.md.
import 'package:flutter/material.dart';

import '../../primitives/primitives.dart';
import 'tutorial_sheet.dart';
import 'tutorial_storage.dart';

/// Shows the onboarding sheet unconditionally, and records that it's been
/// seen. Safe to call any time — this is what a "Replay tutorial" button in
/// Settings should call.
Future<void> showTutorial(BuildContext context) {
  TutorialStorage.markSeen();
  return showZDialog(
    context,
    builder: (context) => const TutorialSheet(),
  );
}

/// Shows the tutorial only the first time it's called for this browser.
/// Intended to be called once, right after sign-in.
Future<void> maybeShowTutorial(BuildContext context) async {
  if (TutorialStorage.hasSeen()) return;
  await showTutorial(context);
}
