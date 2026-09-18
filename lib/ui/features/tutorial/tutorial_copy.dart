// Copy + anchor data for the spotlight tutorial. The words live in
// lib/l10n/strings.dart; this file only pairs them with their targets.
import 'package:flutter/widgets.dart';

import '../../../l10n/strings.dart';
import 'tutorial_targets.dart';

/// One stop of the spotlight tour: the real widget to light up, a one-line
/// title, and one short sentence.
class TutorialStep {
  TutorialStep({
    required this.target,
    required this.title,
    required this.body,
    this.fallbacks = const [],
  });

  final GlobalKey target;

  /// Tried in order when [target] isn't visible (e.g. a compact variant of
  /// the same control in a narrow layout).
  final List<GlobalKey> fallbacks;
  final String title;
  final String body;

  /// [target] first, then [fallbacks].
  List<GlobalKey> get keys => [target, ...fallbacks];
}

/// The real flow, in order: sync Canvas, pick a course, choose the files,
/// pick a study mode, ask a question, visualize an answer, watch the
/// budget, then bring your own key if you need more room.
List<TutorialStep> tutorialStepsFor(S t) => [
      TutorialStep(target: TutorialTargets.sync, title: t.tutorialSyncTitle, body: t.tutorialSyncBody),
      TutorialStep(
        target: TutorialTargets.courses,
        title: t.tutorialCoursesTitle,
        body: t.tutorialCoursesBody,
      ),
      TutorialStep(target: TutorialTargets.files, title: t.tutorialFilesTitle, body: t.tutorialFilesBody),
      TutorialStep(target: TutorialTargets.modes, title: t.tutorialModesTitle, body: t.tutorialModesBody),
      TutorialStep(
        target: TutorialTargets.composer,
        title: t.tutorialComposerTitle,
        body: t.tutorialComposerBody,
      ),
      TutorialStep(
        target: TutorialTargets.visualize,
        title: t.tutorialVisualizeTitle,
        body: t.tutorialVisualizeBody,
      ),
      TutorialStep(
        target: TutorialTargets.budget,
        fallbacks: [TutorialTargets.budgetPill],
        title: t.tutorialBudgetTitle,
        body: t.tutorialBudgetBody,
      ),
      TutorialStep(
        target: TutorialTargets.settings,
        title: t.tutorialSettingsTitle,
        body: t.tutorialSettingsBody,
      ),
    ];

/// The English tour, for code and tests that don't have a BuildContext.
List<TutorialStep> get tutorialSteps => tutorialStepsFor(S.en);
