import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_services.dart';
import 'core/preferences.dart';
import 'ui/features/sign_in/sign_in_screen.dart';
import 'ui/theme.dart';
import 'ui/workspace.dart';

/// Root widget: the themed [MaterialApp]. Everything below [AuthGate] reads
/// services via `Services.of(context)` (installed by `main.dart`).
class ZakerlyApp extends StatelessWidget {
  const ZakerlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Services.of(context).preferences;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => MaterialApp(
        title: 'Zakerly',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light, arabic: prefs.language.isRtl),
        darkTheme: buildTheme(Brightness.dark, arabic: prefs.language.isRtl),
        themeMode: prefs.themeMode,
        locale: prefs.language.locale,
        supportedLocales: [for (final l in AppLanguage.values) l.locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AuthGate(),
      ),
    );
  }
}

/// Listens to [AuthService.user] and shows the sign-in screen when signed
/// out, or the one-screen workspace once a user is present.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Services.of(context).auth;
    return ValueListenableBuilder(
      valueListenable: auth.user,
      builder: (context, user, _) {
        return user == null ? const SignInScreen() : const Workspace();
      },
    );
  }
}
