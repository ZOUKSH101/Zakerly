import 'package:flutter/widgets.dart';

/// Anchors for the spotlight tutorial. Feature panels attach these keys to
/// the real widgets (`key: TutorialTargets.sync`), and the tutorial lights
/// them up one by one. A key that isn't mounted (e.g. a panel hidden on a
/// narrow screen) is skipped.
abstract final class TutorialTargets {
  static final sync = GlobalKey(debugLabel: 'tutorial.sync');
  static final courses = GlobalKey(debugLabel: 'tutorial.courses');
  static final modes = GlobalKey(debugLabel: 'tutorial.modes');
  static final composer = GlobalKey(debugLabel: 'tutorial.composer');
  static final visualize = GlobalKey(debugLabel: 'tutorial.visualize');
  static final files = GlobalKey(debugLabel: 'tutorial.files');
  static final budget = GlobalKey(debugLabel: 'tutorial.budget');
  static final settings = GlobalKey(debugLabel: 'tutorial.settings');
}
