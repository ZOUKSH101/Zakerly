// Copy + anchor data for the spotlight tutorial. Kept separate from the
// overlay widget so the words are easy to review/tweak on their own.
import 'package:flutter/widgets.dart';

import 'tutorial_targets.dart';

/// One stop of the spotlight tour: the real widget to light up, a one-line
/// title, and one short sentence.
class TutorialStep {
  TutorialStep({required this.target, required this.title, required this.body});

  final GlobalKey target;
  final String title;
  final String body;
}

/// The real flow, in order: sync Canvas, pick a course, choose the files,
/// pick a study mode, ask a question, visualize an answer, watch the
/// budget, then bring your own key if you need more room.
final List<TutorialStep> tutorialSteps = [
  TutorialStep(
    target: TutorialTargets.sync,
    title: 'Sync your courses',
    body: 'Tap sync to pull your courses and files from Canvas.',
  ),
  TutorialStep(
    target: TutorialTargets.courses,
    title: 'Pick a course',
    body: 'Tap a course to open it and start studying.',
  ),
  TutorialStep(
    target: TutorialTargets.files,
    title: 'Choose what it reads',
    body: "Pick the files you want. That's all the tutor sees.",
  ),
  TutorialStep(
    target: TutorialTargets.modes,
    title: 'Ask your way',
    body: 'Explain gives you the answer. Guide me helps you figure it out '
        'yourself. Quiz me tests you.',
  ),
  TutorialStep(
    target: TutorialTargets.composer,
    title: 'Type your question',
    body: 'Ask anything about your course material here.',
  ),
  TutorialStep(
    target: TutorialTargets.visualize,
    title: "Watch it, not just read it",
    body: 'Turn any answer into a short animation.',
  ),
  TutorialStep(
    target: TutorialTargets.budget,
    title: 'Keep an eye on your budget',
    body: 'See what you have left, right here.',
  ),
  TutorialStep(
    target: TutorialTargets.settings,
    title: 'Add your own key',
    body: 'Need more room? Add your own key any time.',
  ),
];
