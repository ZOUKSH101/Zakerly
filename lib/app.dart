import 'package:flutter/material.dart';

import 'core/app_services.dart';
import 'ui/features/sign_in/sign_in_screen.dart';
import 'ui/theme.dart';
import 'ui/workspace.dart';

/// Root widget: the themed [MaterialApp]. Everything below [AuthGate] reads
/// services via `Services.of(context)` (installed by `main.dart`).
class ZakerlyApp extends StatelessWidget {
  const ZakerlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zakerly',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
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
