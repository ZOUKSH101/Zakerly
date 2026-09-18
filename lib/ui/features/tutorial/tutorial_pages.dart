// Copy + illustration data for the first-run tutorial. Kept separate from
// the sheet widget so the words are easy to review/tweak on their own.
import 'package:flutter/material.dart';

/// One page of the tutorial: a headline, one short sentence, and one or two
/// icons composed into a small illustration (no image assets).
class TutorialPageData {
  const TutorialPageData({
    required this.headline,
    required this.body,
    required this.icons,
  });

  final String headline;
  final String body;
  final List<IconData> icons;
}

/// The real flow, in order: pick a course from Canvas, choose what files
/// feed the tutor, ask questions in a study mode, visualize an answer, then
/// keep an eye on the budget (or bring your own key).
const List<TutorialPageData> tutorialPages = [
  TutorialPageData(
    headline: 'Pick a course',
    body: 'Sync Canvas on the left, then tap a course to open it.',
    icons: [Icons.cloud_sync_outlined, Icons.school_outlined],
  ),
  TutorialPageData(
    headline: 'You choose what it reads',
    body: "Check the files you want in Status — that's all the tutor sees.",
    icons: [Icons.description_outlined, Icons.check_circle_outline],
  ),
  TutorialPageData(
    headline: 'Ask, your way',
    body: 'Type a question and pick Explain, Socratic, or Quiz me above the chat.',
    icons: [Icons.chat_bubble_outline, Icons.quiz_outlined],
  ),
  TutorialPageData(
    headline: "Watch it, don't just read it",
    body: 'Tap Visualize on any answer for a quick animation — cached for your '
        'whole class, so it costs less.',
    icons: [Icons.auto_awesome_motion, Icons.groups_outlined],
  ),
  TutorialPageData(
    headline: 'Your budget, always in view',
    body: "See what's left on the right. Need more? Add your own key in Settings.",
    icons: [Icons.donut_large_outlined, Icons.vpn_key_outlined],
  ),
];
