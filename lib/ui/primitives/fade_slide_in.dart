import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// The Apple stagger: translate settles first (700ms, decel), opacity
/// finishes after (900ms, decel), delayed by `index * 90ms` (capped at
/// index 8). Skips the animation entirely when
/// `MediaQuery.disableAnimationsOf` is true.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.index, this.offset = 8, required this.child});

  final int index;
  final double offset;
  final Widget child;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ZMotion.staggerOpacity,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: ZMotion.decel,
  );
  late final Animation<double> _translate = Tween<double>(begin: widget.offset, end: 0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Interval(0, _translateFraction, curve: ZMotion.decel),
    ),
  );

  /// Stagger delay; cancelled on dispose so no timer outlives the widget.
  Timer? _delay;

  double get _translateFraction => (ZMotion.staggerTranslate.inMilliseconds /
          ZMotion.staggerOpacity.inMilliseconds)
      .clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
      return;
    }
    final cappedIndex = widget.index.clamp(0, ZMotion.staggerMaxIndex);
    final delay = Duration(milliseconds: cappedIndex * ZMotion.staggerStepMs);
    _delay = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, _translate.value), child: child),
        );
      },
      child: widget.child,
    );
  }
}
