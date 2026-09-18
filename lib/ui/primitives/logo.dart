import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The Zakerly mark (docs/brand/BRAND.md s.2): one continuous rounded "Z"
/// pen stroke on a Hibiscus tile. The bottom stroke runs longer than the
/// top, reading as the pen finishing with an underline, and an amber spark
/// sits where the pen lifts off (top right). The tile carries its own
/// background, so the mark reads the same on light and dark surfaces.
///
/// Set [withWordmark] to add the inline "Zakerly" / "ذاكرلي" lockup.
///
/// "The mark writes itself": the first [ZLogo] shown in a session draws the
/// Z from point 1 to 4 ([ZMotion.draw], decel), then the spark pops from 0
/// with overshoot ([ZMotion.spark], starting at 520ms). Later instances
/// appear settled. Skipped entirely when [animate] is false or
/// `MediaQuery.disableAnimationsOf` is true.
class ZLogo extends StatefulWidget {
  const ZLogo({super.key, this.size = 32, this.withWordmark = false, this.animate = true});

  /// Edge length of the mark's square, in logical pixels.
  final double size;

  /// Adds the English + Arabic wordmark beside the mark.
  final bool withWordmark;

  /// Plays the first-appearance animation (once per session).
  final bool animate;

  /// Set once the write-on has played; keeps it to once per session.
  static bool _playedThisSession = false;

  @override
  State<ZLogo> createState() => _ZLogoState();
}

class _ZLogoState extends State<ZLogo> with SingleTickerProviderStateMixin {
  static const int _sparkStartMs = 520;
  static final int _totalMs = _sparkStartMs + ZMotion.spark.inMilliseconds;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _totalMs),
    value: 1.0,
  );

  late final Animation<double> _tile = CurvedAnimation(
    parent: _controller,
    curve: Interval(0, 240 / _totalMs, curve: ZMotion.decel),
  );
  late final Animation<double> _draw = CurvedAnimation(
    parent: _controller,
    curve: Interval(0, ZMotion.draw.inMilliseconds / _totalMs, curve: ZMotion.decel),
  );
  late final Animation<double> _spark = CurvedAnimation(
    parent: _controller,
    curve: Interval(_sparkStartMs / _totalMs, 1, curve: ZMotion.overshoot),
  );

  bool get _shouldPlay => widget.animate && !ZLogo._playedThisSession;

  @override
  void initState() {
    super.initState();
    if (_shouldPlay) {
      ZLogo._playedThisSession = true;
      _controller.value = 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _start() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final reduced = MediaQuery.disableAnimationsOf(context);

    final mark = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final settled = reduced || _controller.isCompleted;
          return Opacity(
            opacity: settled ? 1.0 : _tile.value.clamp(0.0, 1.0),
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _ZMarkPainter(
                fill: z.accent,
                stroke: z.onAccent,
                spark: z.spark,
                drawProgress: settled ? 1.0 : _draw.value,
                sparkScale: settled ? 1.0 : _spark.value,
              ),
            ),
          );
        },
      ),
    );

    if (!widget.withWordmark) return Semantics(label: 'Zakerly', image: true, child: mark);

    // Inline lockup: Latin 600 at -0.01em; Arabic 500, never letter-spaced.
    final headline = context.type.titleMedium;
    final english = headline?.copyWith(
      color: z.text,
      letterSpacing: -0.01 * (headline.fontSize ?? ZType.headline),
    );
    final label = context.type.labelLarge;
    final arabic = label == null
        ? null
        : ZType.arabic(ZType.withWeight(label, FontWeight.w500)).copyWith(color: z.textSecondary);

    return Semantics(
      label: 'Zakerly',
      container: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: ZSpace.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Zakerly', style: english),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text('ذاكرلي', style: arabic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the mark on the brand's 64-unit grid, expressed as fractions of
/// the tile side so it scales continuously from favicon to splash.
/// [drawProgress] (0..1) draws the pen stroke along its length;
/// [sparkScale] scales the amber spark (may overshoot past 1).
class _ZMarkPainter extends CustomPainter {
  _ZMarkPainter({
    required this.fill,
    required this.stroke,
    required this.spark,
    this.drawProgress = 1.0,
    this.sparkScale = 1.0,
  });

  final Color fill;
  final Color stroke;
  final Color spark;
  final double drawProgress;
  final double sparkScale;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Rect.fromLTWH((size.width - s) / 2, (size.height - s) / 2, s, s);
    Offset p(double x, double y) => rect.topLeft + Offset(x * s, y * s);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s * 0.28)),
      Paint()..color = fill,
    );

    // M17 23 H37 L19 44 H45 on the 64 grid.
    final p1 = p(0.265625, 0.359375);
    final p2 = p(0.578125, 0.359375);
    final p3 = p(0.296875, 0.6875);
    final p4 = p(0.703125, 0.6875);
    final z = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy);

    final pen = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.140625
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final t = drawProgress.clamp(0.0, 1.0);
    if (t >= 1.0) {
      canvas.drawPath(z, pen);
    } else if (t > 0.0) {
      final metrics = z.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final PathMetric m = metrics.first;
        canvas.drawPath(m.extractPath(0, m.length * t), pen);
      }
    }

    final r = s * 0.0625 * (sparkScale < 0 ? 0 : sparkScale);
    if (r > 0) canvas.drawCircle(p(0.75, 0.25), r, Paint()..color = spark);
  }

  @override
  bool shouldRepaint(covariant _ZMarkPainter old) {
    return old.fill != fill ||
        old.stroke != stroke ||
        old.spark != spark ||
        old.drawProgress != drawProgress ||
        old.sparkScale != sparkScale;
  }
}
