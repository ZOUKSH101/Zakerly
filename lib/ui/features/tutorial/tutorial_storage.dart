// Persists whether the first-run tutorial has already been shown.
import 'package:web/web.dart' as web;

/// Tracks the "seen" flag for the first-run tutorial.
///
/// Backed by `window.localStorage` so the tutorial shows once per browser,
/// not once per tab. `localStorage` access is wrapped in try/catch — some
/// browsers throw when storage is blocked (private-browsing settings,
/// disabled cookies/storage, or a non-web test environment) — and falls
/// back to an in-memory flag that only lasts the current session.
class TutorialStorage {
  TutorialStorage._();

  static const String _key = 'zakerly.tutorial.seen';

  static bool _sessionFallback = false;

  /// Whether the tutorial has already been shown (this browser, or this
  /// session if storage is unavailable).
  static bool hasSeen() {
    try {
      return web.window.localStorage.getItem(_key) != null;
    } catch (_) {
      return _sessionFallback;
    }
  }

  /// Records that the tutorial has been shown.
  static void markSeen() {
    try {
      web.window.localStorage.setItem(_key, '1');
    } catch (_) {
      _sessionFallback = true;
    }
  }
}
