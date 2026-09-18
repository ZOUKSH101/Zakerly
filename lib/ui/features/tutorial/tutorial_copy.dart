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
    title: 'Your courses, synced',
    body: 'I brought in your courses and files from Canvas. Tap Sync any time to get new ones.',
  ),
  TutorialStep(
    target: TutorialTargets.courses,
    title: 'Pick a course',
    body: 'Tap one to open it. The ring fills as I read its files.',
  ),
  TutorialStep(
    target: TutorialTargets.files,
    title: 'Choose what I read',
    body: 'I only use the files you tick here.',
  ),
  TutorialStep(
    target: TutorialTargets.modes,
    title: 'Pick how I help',
    body: 'Explain gives you a clear answer. Guide me gives you hints so you '
        'work it out. Quiz me tests you.',
  ),
  TutorialStep(
    target: TutorialTargets.composer,
    title: 'Ask your question',
    body: "Ask anything from your slides. I'll show which file each answer came from.",
  ),
  TutorialStep(
    target: TutorialTargets.visualize,
    title: 'Watch it move',
    body: 'Turn my last answer into a short animation.',
  ),
  TutorialStep(
    target: TutorialTargets.budget,
    title: 'Your budget',
    body: 'This is how much you have left this month.',
  ),
  TutorialStep(
    target: TutorialTargets.settings,
    title: 'Plans and keys',
    body: 'Need more? Switch plans or add your own API key here.',
  ),
];
