// Public API for the first-run tutorial feature. See CONTRACT.md.
import 'package:flutter/material.dart';

import 'tutorial_overlay.dart';
import 'tutorial_storage.dart';

/// A short delay after the first frame, so panels that load their own data
/// (course list, sync state) have finished laying out before the tour
/// measures its targets.
const Duration _layoutSettleDelay = Duration(milliseconds: 300);

/// Shows the spotlight tour unconditionally, and records that it's been
/// seen. Safe to call any time — this is what a "Show tutorial again"
/// button in Settings should call.
Future<void> showTutorial(BuildContext context) {
  TutorialStorage.markSeen();
  return showSpotlightTutorial(context);
}

/// Shows the tour only the first time it's called for this browser.
/// Waits until after the first frame, plus a short settle delay, so the
/// widgets it lights up are actually laid out. Intended to be called once,
/// right after sign-in.
Future<void> maybeShowTutorial(BuildContext context) async {
  if (TutorialStorage.hasSeen()) return;
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(_layoutSettleDelay);
  if (!context.mounted) return;
  await showTutorial(context);
}
