import 'package:flutter/material.dart';

import '../theme.dart';

/// The Zakerly mark: a single continuous rounded "Z" stroke — half
/// underline, half pen stroke, since the tutor draws its answers — sitting
/// on an accent-filled rounded square. The square carries its own
/// background, so the mark is self-contained and reads the same whether the
/// host surface is light or dark; only the accent (and therefore the mark)
/// swaps with [ZTokens.light] / [ZTokens.dark].
///
/// Set [withWordmark] to add the "Zakerly" / "ذاكرلي" lockup beside it. On
/// first build the mark eases in (scale + fade, arrival curve) unless
/// [animate] is false or `MediaQuery.disableAnimationsOf` is true.
class ZLogo extends StatefulWidget {
  const ZLogo({super.key, this.size = 32, this.withWordmark = false, this.animate = true});

  /// Edge length of the mark's square, in logical pixels.
  final double size;

  /// Adds the English + Arabic wordmark beside the mark.
  final bool withWordmark;

  /// Plays the entrance animation. Ignored (treated as settled) when
  /// `MediaQuery.disableAnimationsOf` is true.
  final bool animate;

  @override
  State<ZLogo> createState() => _ZLogoState();
}

class _ZLogoState extends State<ZLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ZMotion.enter,
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.86, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: ZMotion.overshoot),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: ZMotion.decel,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
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

    final mark = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ZMarkPainter(fill: z.accent, stroke: z.onAccent),
      ),
    );

    if (!widget.withWordmark) return mark;

    final english = context.type.titleMedium?.copyWith(color: z.text);
    final arabic = context.type.labelLarge?.copyWith(color: z.textSecondary);

    return Row(
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
    );
  }
}

/// Paints the mark: an accent-filled rounded square with a bold rounded "Z"
/// stroke cut from [stroke]. Proportions are fractions of the painted
/// square (matching the discipline in `ZRing`'s stroke sizing), not tokens —
/// the mark must scale continuously from favicon to hero sizes.
class _ZMarkPainter extends CustomPainter {
  _ZMarkPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final rect = Rect.fromLTWH(
      (size.width - side) / 2,
      (size.height - side) / 2,
      side,
      side,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(side * 0.28)),
      Paint()..color = fill,
    );

    final inset = side * 0.24;
    final x0 = rect.left + inset;
    final x1 = rect.right - inset;
    final y0 = rect.top + inset;
    final y1 = rect.bottom - inset;

    final zPath = Path()
      ..moveTo(x0, y0)
      ..lineTo(x1, y0)
      ..lineTo(x0, y1)
      ..lineTo(x1, y1);

    canvas.drawPath(
      zPath,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ZMarkPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.stroke != stroke;
  }
}
