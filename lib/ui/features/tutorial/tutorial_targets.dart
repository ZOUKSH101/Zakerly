import 'package:flutter/widgets.dart';

/// Anchors for the spotlight tutorial. Feature panels attach these keys to
/// the real widgets (`key: TutorialTargets.sync`), and the tutorial lights
/// them up one by one. A key that isn't mounted, or that is mounted but
/// can't actually be hit (e.g. a hidden IndexedStack tab, or something
/// under another layer), is skipped.
abstract final class TutorialTargets {
  static final sync = GlobalKey(debugLabel: 'tutorial.sync');
  static final courses = GlobalKey(debugLabel: 'tutorial.courses');
  static final modes = GlobalKey(debugLabel: 'tutorial.modes');
  static final composer = GlobalKey(debugLabel: 'tutorial.composer');
  static final visualize = GlobalKey(debugLabel: 'tutorial.visualize');
  static final files = GlobalKey(debugLabel: 'tutorial.files');
  static final budget = GlobalKey(debugLabel: 'tutorial.budget');

  /// The compact budget pill shown in narrow layouts (where the Status
  /// column with [budget] is hidden). The budget step falls back to it.
  static final budgetPill = GlobalKey(debugLabel: 'tutorial.budgetPill');
  static final settings = GlobalKey(debugLabel: 'tutorial.settings');
}
