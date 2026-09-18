import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

enum AppLanguage {
  english('en', 'English'),
  arabic('ar', 'العربية');

  const AppLanguage(this.code, this.nativeName);
  final String code;
  final String nativeName;

  Locale get locale => Locale(code);
  bool get isRtl => this == arabic;
}

/// Per-device display preferences: theme and language. Kept in the browser's
/// localStorage, never in the shared database.
class AppPreferences extends ChangeNotifier {
  AppPreferences() {
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _read(_themeKey),
      orElse: () => ThemeMode.system,
    );
    language = AppLanguage.values.firstWhere(
      (l) => l.code == _read(_langKey),
      orElse: () => AppLanguage.english,
    );
  }

  static const _themeKey = 'zakerly.theme';
  static const _langKey = 'zakerly.lang';

  late ThemeMode themeMode;
  late AppLanguage language;

  void setThemeMode(ThemeMode mode) {
    if (mode == themeMode) return;
    themeMode = mode;
    _write(_themeKey, mode.name);
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    if (lang == language) return;
    language = lang;
    _write(_langKey, lang.code);
    notifyListeners();
  }

  static String? _read(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null; // Storage blocked (private mode etc.) — use defaults.
    }
  }

  static void _write(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {}
  }
}
