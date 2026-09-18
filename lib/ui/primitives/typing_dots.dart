import 'package:flutter/material.dart';

import '../theme.dart';

/// Three-dot "typing" indicator (textTertiary), bouncing in a loop while
/// animations are enabled. Announces itself once as a live region; the dots
/// themselves are excluded from the semantics tree.
class ZTypingDots extends StatefulWidget {
  const ZTypingDots({super.key});

  @override
  State<ZTypingDots> createState() => _ZTypingDotsState();
}

class _ZTypingDotsState extends State<ZTypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ZMotion.typingCycle,
  );

  bool? _animated;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animated = !MediaQuery.disableAnimationsOf(context);
    if (animated == _animated) return;
    _animated = animated;
    if (animated) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Semantics(
      liveRegion: true,
      label: 'Tutor is typing',
      child: ExcludeSemantics(
        child: SizedBox(
          height: ZSpace.s12,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: ZSpace.s4),
                    _Dot(t: _controller.value, phase: i * 0.2, color: z.textTertiary),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.t, required this.phase, required this.color});

  static const double _diameter = ZSpace.s8 - 2;
  static const double _travel = ZSpace.s4;

  final double t;
  final double phase;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final local = (t + phase) % 1.0;
    final bounce = Curves.easeInOut.transform(local < 0.5 ? local * 2 : (1 - local) * 2);
    return Transform.translate(
      offset: Offset(0, -_travel * bounce),
      child: Container(
        width: _diameter,
        height: _diameter,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
