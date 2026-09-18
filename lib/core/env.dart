/// Build-time config, injected with --dart-define by CI (see
/// .github/workflows/deploy.yml). Empty in local runs, which keeps the app on
/// its mocks. Never put server secrets (the Gemini key) here: everything in
/// this file ships to the browser.
class Env {
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const firebaseDatabaseUrl = String.fromEnvironment('FIREBASE_DATABASE_URL');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');

  static bool get hasFirebase => firebaseApiKey.isNotEmpty && firebaseProjectId.isNotEmpty;
}
