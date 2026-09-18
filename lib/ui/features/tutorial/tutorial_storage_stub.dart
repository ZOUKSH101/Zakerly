// Non-web fallback for the tutorial "seen" flag (e.g. `flutter test`'s
// default VM platform, which can't load dart:js_interop / package:web).
// Zakerly itself only ships for web, so this path never runs in production
// — it exists purely so tests don't need `--platform chrome`.
class TutorialStorageImpl {
  TutorialStorageImpl._();

  static bool _seen = false;

  static bool hasSeen() => _seen;

  static void markSeen() => _seen = true;
}
