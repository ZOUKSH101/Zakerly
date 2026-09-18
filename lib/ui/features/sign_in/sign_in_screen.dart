import 'package:flutter/material.dart';

import 'package:zakerly/core/app_services.dart';

import '../../primitives/primitives.dart';

enum _Pending { none, email, google }

/// The sign-in screen. Full-viewport, centered, no scrolling. On a
/// successful sign-in this does nothing further — the app's AuthGate
/// swaps to the workspace once [AuthService.user] updates.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  _Pending _pending = _Pending.none;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String _messageFor(Object e) {
    debugPrint('sign-in failed: $e');
    return 'Sign-in failed. Check your email and password and try again.';
  }

  Future<void> _submitEmail() async {
    if (_pending != _Pending.none) return;
    setState(() {
      _pending = _Pending.email;
      _error = null;
    });
    try {
      await Services.of(context).auth.signInWithEmail(
            _emailController.text,
            _passwordController.text,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _pending = _Pending.none);
    }
  }

  Future<void> _submitGoogle() async {
    if (_pending != _Pending.none) return;
    setState(() {
      _pending = _Pending.google;
      _error = null;
    });
    try {
      await Services.of(context).auth.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _pending = _Pending.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final type = context.type;
    final emailLoading = _pending == _Pending.email;
    final googleLoading = _pending == _Pending.google;
    final busy = _pending != _Pending.none;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ZLayout.formMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZSpace.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Zakerly', style: type.displaySmall),
                          const SizedBox(width: ZSpace.s12),
                          Text(
                            'ذاكرلي',
                            locale: const Locale('ar'),
                            style: type.titleLarge?.copyWith(color: z.accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: ZSpace.s8),
                      Text(
                        'Your Canvas courses, a tutor that reads them, '
                        'and a budget you can always see.',
                        textAlign: TextAlign.center,
                        style: type.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ZSpace.s24),
                AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(
                        index: 1,
                        child: ZTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Email',
                          enabled: !busy,
                          autofillHints: const [AutofillHints.email],
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: ZSpace.s12),
                      FadeSlideIn(
                        index: 2,
                        child: ZTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          label: 'Password',
                          hint: 'Password',
                          obscure: true,
                          enabled: !busy,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitEmail(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: ZSpace.s12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: type.bodySmall?.copyWith(color: z.danger),
                    ),
                  ),
                ],
                const SizedBox(height: ZSpace.s20),
                FadeSlideIn(
                  index: 3,
                  child: ZButton(
                    label: 'Continue',
                    loading: emailLoading,
                    onPressed: busy ? null : _submitEmail,
                  ),
                ),
                const SizedBox(height: ZSpace.s12),
                FadeSlideIn(
                  index: 4,
                  child: ZButton(
                    label: 'Continue with Google',
                    variant: ZButtonVariant.tonal,
                    loading: googleLoading,
                    onPressed: busy ? null : _submitGoogle,
                  ),
                ),
                const SizedBox(height: ZSpace.s24),
                FadeSlideIn(
                  index: 5,
                  child: Text(
                    'Demo build: any email works. Firebase Auth plugs in here.',
                    textAlign: TextAlign.center,
                    style: type.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
