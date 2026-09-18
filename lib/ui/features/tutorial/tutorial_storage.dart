// Persists whether the first-run tutorial has already been shown.
//
// Real builds are web-only (see CONTRACT.md), so `tutorial_storage_web.dart`
// (window.localStorage via package:web) is what actually ships. The stub is
// selected only when `dart:js_interop` isn't available on the compile
// target — i.e. `flutter test`'s default VM platform — so tests don't need
// `--platform chrome`.
import 'tutorial_storage_stub.dart' if (dart.library.js_interop) 'tutorial_storage_web.dart';

/// Tracks the "seen" flag for the first-run tutorial, so it shows once per
/// browser (see [TutorialStorageImpl] for the platform-specific backing
/// store).
class TutorialStorage {
  TutorialStorage._();

  static bool hasSeen() => TutorialStorageImpl.hasSeen();

  static void markSeen() => TutorialStorageImpl.markSeen();
}
