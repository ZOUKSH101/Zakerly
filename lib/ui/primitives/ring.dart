import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Circular progress ring. Animates value changes; color follows [fraction]
/// thresholds unless [color] overrides it (accent below 0.7, warning below
/// 0.9, danger at or above 0.9).
class ZRing extends StatelessWidget {
  const ZRing({
    super.key,
    required this.fraction,
    this.size = 48,
    this.stroke,
    this.center,
    this.color,
  });

  final double fraction;
  final double size;
  /// Stroke width. Defaults to `size / 8`, clamped to 2..6, so small rings
  /// don't blob into a filled circle.
  final double? stroke;
  final Widget? center;
  final Color? color;

  static Color colorForFraction(ZTokens z, double f, {Color? override}) {
    if (override != null) return override;
    if (f < 0.7) return z.accent;
    if (f < 0.9) return z.warning;
    return z.danger;
  }

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final clamped = fraction.clamp(0.0, 1.0);
    final effStroke = stroke ?? (size / 8).clamp(2.0, 6.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: ZMotion.medium,
      curve: ZMotion.standard,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  fraction: value,
                  stroke: effStroke,
                  trackColor: z.raised2,
                  color: colorForFraction(z, value, override: color),
                ),
              ),
              ?center,
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.stroke,
    required this.trackColor,
    required this.color,
  });

  final double fraction;
  final double stroke;
  final Color trackColor;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    final sweep = 2 * math.pi * fraction;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.stroke != stroke ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.color != color;
  }
}
