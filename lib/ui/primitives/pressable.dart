import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Wraps [child] with iOS-style press-scale feedback: 0.97 on press-in,
/// springing back to 1.0 on release. Press-in uses exit timing (fast,
/// ease-in); release uses medium timing with the overshoot curve.
///
/// Also keyboard-focusable and screen-reader-accessible: Enter/Space
/// activate [onTap], and a visible focus ring in `z.accent` is drawn while
/// focus is shown (keyboard/traversal). Pass [semanticLabel] when [child]
/// doesn't already convey the action to assistive tech (e.g. icon-only
/// content without its own label).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  static const double _pressedScale = 0.97;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ZMotion.exit,
    lowerBound: _pressedScale,
    upperBound: 1.0,
    value: 1.0,
  );

  bool _showFocusRing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target, Duration duration, Curve curve) {
    _controller.animateTo(target, duration: duration, curve: curve);
  }

  void _onTapDown(TapDownDetails _) => _animateTo(_pressedScale, ZMotion.exit, ZMotion.exitCurve);

  void _onTapUpOrCancel() => _animateTo(1.0, ZMotion.medium, ZMotion.overshoot);

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final interactive = widget.onTap != null;

    return Semantics(
      button: true,
      enabled: interactive,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: interactive ? widget.onTap : null,
      child: FocusableActionDetector(
        enabled: interactive,
        mouseCursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        onShowFocusHighlight: (show) {
          if (mounted) setState(() => _showFocusRing = show);
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: widget.onTap,
          onTapDown: interactive ? _onTapDown : null,
          onTapUp: interactive ? (_) => _onTapUpOrCancel() : null,
          onTapCancel: interactive ? _onTapUpOrCancel : null,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(scale: _controller.value, child: child),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: _showFocusRing ? Border.all(color: z.accentText, width: 2) : null,
                borderRadius: _showFocusRing ? BorderRadius.circular(ZRadius.md) : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
