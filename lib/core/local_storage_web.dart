import 'package:web/web.dart' as web;

String? readLocal(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } catch (_) {
    return null; // Storage blocked (private mode etc.): use defaults.
  }
}

void writeLocal(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (_) {}
}
