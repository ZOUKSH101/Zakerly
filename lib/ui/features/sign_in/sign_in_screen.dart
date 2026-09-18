import 'package:flutter/material.dart';

import 'package:zakerly/core/app_services.dart';

import '../../primitives/primitives.dart';

enum _Pending { none, email, google }

/// The sign-in screen. Centered when there's room; the form scrolls on its
/// own if the viewport is too short to fit it (e.g. a small browser window).
/// On a successful sign-in this does nothing further — the app's AuthGate
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
    return 'That didn\'t work. Check your email and password and try again.';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZSpace.s24,
                    vertical: ZSpace.s24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: ZLayout.formMaxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: _GlowingMark()),
                        const SizedBox(height: ZSpace.s24),
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
                                  Text('Zakerly', style: type.displayLarge),
                                  const SizedBox(width: ZSpace.s12),
                                  Text(
                                    'ذاكرلي',
                                    locale: const Locale('ar'),
                                    style: type.titleLarge == null
                                        ? null
                                        : ZType.arabic(
                                            ZType.withWeight(type.titleLarge!, FontWeight.w500),
                                          ).copyWith(color: z.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: ZSpace.s12),
                              Text(
                                'I already read your slides. Sign in and let\'s study.',
                                textAlign: TextAlign.center,
                                style: type.bodyLarge?.copyWith(color: z.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: ZSpace.s32),
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
                        const SizedBox(height: ZSpace.s24),
                        FadeSlideIn(
                          index: 3,
                          child: ZButton(
                            label: 'Continue',
                            size: ZButtonSize.lg,
                            expand: true,
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
                            size: ZButtonSize.lg,
                            expand: true,
                            loading: googleLoading,
                            onPressed: busy ? null : _submitGoogle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The big mark that writes itself (BRAND.md delight 1), over a wide, very
/// soft Hibiscus wash on the page. The wash sits on the background, never on
/// the tile, so the mark itself stays flat as the brand asks.
class _GlowingMark extends StatelessWidget {
  const _GlowingMark();

  static const double _mark = 72;
  static const double _glowReach = 170;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glow = z.accent.withValues(alpha: dark ? 0.20 : 0.11);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: _mark,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -_glowReach,
            top: -_glowReach,
            right: -_glowReach,
            bottom: -_glowReach,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: reduced ? 1 : 0, end: 1),
                duration: ZMotion.staggerOpacity,
                curve: ZMotion.decel,
                builder: (context, t, child) => Opacity(opacity: t, child: child),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [glow, glow.withValues(alpha: 0)],
                      stops: const [0, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const ZLogo(size: _mark),
        ],
      ),
    );
  }
}
