import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A brief amber burst: the brand's "something just clicked" moment
/// (docs/brand/BRAND.md s.5, delight 2 "Course ready").
///
/// The spark pops in with overshoot, throws six short rays, then hops 8px
/// up and fades out, all within [ZMotion.sparkHop] (500ms). Afterwards it
/// paints nothing. It plays when [fired] flips from false to true (so a
/// course that was already ready on first build stays quiet), or on mount
/// when [playOnMount] is true. With `MediaQuery.disableAnimationsOf` the
/// moment is skipped entirely (no static spark is left behind).
///
/// Give it a [child] to paint the burst over it (e.g. a `ZRing`), centred
/// on the child's [alignment] point (default: top centre) and free to
/// overflow it. Without a child it occupies a `size * 3` square.
///
/// ```dart
/// ZSpark(fired: course.isReady, child: ZRing(fraction: p, color: z.success))
/// ```
class ZSpark extends StatefulWidget {
  const ZSpark({
    super.key,
    required this.fired,
    this.size = 10,
    this.child,
    this.alignment = Alignment.topCenter,
    this.playOnMount = false,
    this.onDone,
  });

  /// Plays the burst on a false -> true transition.
  final bool fired;

  /// Diameter of the spark dot at rest, in logical pixels.
  final double size;

  /// Optional widget the burst sits on.
  final Widget? child;

  /// Where on [child] the spark is centred.
  final Alignment alignment;

  /// Plays once on mount if [fired] is already true.
  final bool playOnMount;

  /// Called when the burst finishes (or immediately if it was skipped).
  final VoidCallback? onDone;

  @override
  State<ZSpark> createState() => _ZSparkState();
}

class _ZSparkState extends State<ZSpark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ZMotion.sparkHop,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone?.call();
    });

  @override
  void initState() {
    super.initState();
    if (widget.fired && widget.playOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(covariant ZSpark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fired && !oldWidget.fired) _play();
  }

  void _play() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onDone?.call();
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.z.spark;
    final child = widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: child,
        builder: (context, child) {
          final painter = _SparkPainter(
            t: _controller.isAnimating ? _controller.value : 0,
            color: color,
            radius: widget.size / 2,
            anchor: child == null ? Alignment.center : widget.alignment,
          );
          if (child == null) {
            return IgnorePointer(
              child: CustomPaint(size: Size.square(widget.size * 3), painter: painter),
            );
          }
          // Foreground painter: drawn over the child, free to overflow it.
          return CustomPaint(foregroundPainter: painter, child: child);
        },
      ),
    );
  }
}

/// The brand spark at rest, as a small static glyph: the amber pen-lift dot
/// with four short rays. Use it where an icon would go for delight moments
/// (e.g. the "already drawn for your class" cache badge). Decorative.
class ZSparkGlyph extends StatelessWidget {
  const ZSparkGlyph({super.key, this.size = 12, this.color});

  final double size;

  /// Defaults to `z.spark`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SparkGlyphPainter(color ?? context.z.spark),
      ),
    );
  }
}

class _SparkGlyphPainter extends CustomPainter {
  _SparkGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.shortestSide;
    canvas.drawCircle(c, s * 0.2, Paint()..color = color);
    final ray = Paint()
      ..color = color
      ..strokeWidth = math.max(1.2, s * 0.12)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (s * 0.34), c + d * (s * 0.46), ray);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkGlyphPainter old) => old.color != color;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.t,
    required this.color,
    required this.radius,
    required this.anchor,
  });

  /// 0..1 through the burst; 0 paints nothing.
  final double t;
  final Color color;
  final double radius;
  /// Where the spark starts, within the painted box.
  final Alignment anchor;

  static const int _rays = 6;
  static const double _hop = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;

    // Pop (0..0.45, overshoot), hop + fade (0.45..1, decel / ease-in).
    final pop = ZMotion.overshoot.transform((t / 0.45).clamp(0.0, 1.0));
    final tail = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    final hop = ZMotion.decel.transform(tail) * _hop;
    final fade = 1 - ZMotion.exitCurve.transform(tail);

    final center = anchor.withinRect(Offset.zero & size).translate(0, -hop);
    final paint = Paint()..color = color.withValues(alpha: color.a * fade);
    canvas.drawCircle(center, radius * pop, paint);

    // Rays: grow outwards during the pop, gone by 70%.
    final rayT = (t / 0.7).clamp(0.0, 1.0);
    if (rayT < 1) {
      final rayFade = 1 - rayT;
      final inner = radius * (1.3 + 0.9 * ZMotion.decel.transform(rayT));
      final outer = inner + radius * 0.9 * (1 - rayT);
      final ray = Paint()
        ..color = color.withValues(alpha: color.a * rayFade)
        ..strokeWidth = math.max(1.5, radius * 0.4)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < _rays; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / _rays;
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(center + d * inner, center + d * outer, ray);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.t != t || old.color != color || old.radius != radius || old.anchor != anchor;
}
