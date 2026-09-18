// Web implementation of the tutorial "seen" flag: package:web/localStorage.
import 'package:web/web.dart' as web;

class TutorialStorageImpl {
  TutorialStorageImpl._();

  static const String _key = 'zakerly.tutorial.seen';

  static bool _sessionFallback = false;

  /// `localStorage` access is wrapped in try/catch — some browsers throw
  /// when storage is blocked (private-browsing settings, disabled
  /// cookies/storage) — and falls back to an in-memory flag that only lasts
  /// the current session.
  static bool hasSeen() {
    try {
      return web.window.localStorage.getItem(_key) != null;
    } catch (_) {
      return _sessionFallback;
    }
  }

  static void markSeen() {
    try {
      web.window.localStorage.setItem(_key, '1');
    } catch (_) {
      _sessionFallback = true;
    }
  }
}
