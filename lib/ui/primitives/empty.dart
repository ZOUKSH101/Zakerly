import 'package:flutter/material.dart';

import '../theme.dart';

/// Single-stroke empty-state drawings (docs/brand/BRAND.md s.5, delight 6).
enum ZEmptyArt {
  /// An open notebook: "no courses yet".
  notebook,

  /// A speech bubble: "new chat".
  bubble,
}

/// Centered empty-state placeholder: a small pen-drawn illustration, title,
/// optional message/action.
///
/// The illustration is drawn on once when the widget appears, in the same
/// pen as the logo: 1.75px round-cap lines in `textTertiary`, plus one
/// amber dot where the pen lifts. With [art] it draws that picture; without,
/// it draws a pen circle around [icon]. With reduced motion it appears
/// already drawn.
class ZEmpty extends StatelessWidget {
  const ZEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.art,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final ZEmptyArt? art;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ZSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: ZPenDrawing(art: art, icon: icon)),
            const SizedBox(height: ZSpace.s12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.type.titleMedium?.copyWith(color: z.text),
            ),
            if (message != null) ...[
              const SizedBox(height: ZSpace.s4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.type.bodyMedium?.copyWith(color: z.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: ZSpace.s16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The draw-on illustration used by [ZEmpty]. Decorative.
class ZPenDrawing extends StatefulWidget {
  const ZPenDrawing({super.key, this.art, this.icon, this.size = 56});

  final ZEmptyArt? art;

  /// Shown inside the pen circle when [art] is null.
  final IconData? icon;
  final double size;

  @override
  State<ZPenDrawing> createState() => _ZPenDrawingState();
}

class _ZPenDrawingState extends State<ZPenDrawing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ZMotion.draw + ZMotion.spark,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
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
    final total = (ZMotion.draw + ZMotion.spark).inMilliseconds;
    final drawEnd = ZMotion.draw.inMilliseconds / total;
    final stroke = CurvedAnimation(
      parent: _controller,
      curve: Interval(0, drawEnd, curve: ZMotion.decel),
    );
    final dot = CurvedAnimation(
      parent: _controller,
      curve: Interval(drawEnd, 1, curve: ZMotion.overshoot),
    );
    final icon = widget.icon;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _PenPainter(
            art: widget.art,
            progress: stroke.value,
            dotScale: dot.value,
            ink: z.textTertiary,
            spark: z.spark,
          ),
          child: widget.art == null && icon != null
              ? Center(
                  child: Opacity(
                    opacity: stroke.value.clamp(0.0, 1.0),
                    child: Icon(icon, size: widget.size * 0.4, color: z.textSecondary),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _PenPainter extends CustomPainter {
  _PenPainter({
    required this.art,
    required this.progress,
    required this.dotScale,
    required this.ink,
    required this.spark,
  });

  final ZEmptyArt? art;
  final double progress;
  final double dotScale;
  final Color ink;
  final Color spark;

  /// The drawing on a 48x48 grid, plus where the pen lifts (the amber dot).
  (Path, Offset) _shape() {
    switch (art) {
      case ZEmptyArt.notebook:
        final p = Path()
          ..moveTo(24, 15)
          ..quadraticBezierTo(15, 10, 6, 12)
          ..lineTo(6, 36)
          ..quadraticBezierTo(15, 34, 24, 39)
          ..quadraticBezierTo(33, 34, 42, 36)
          ..lineTo(42, 12)
          ..quadraticBezierTo(33, 10, 24, 15)
          ..lineTo(24, 39)
          ..moveTo(11, 19)
          ..lineTo(19, 20)
          ..moveTo(11, 25)
          ..lineTo(19, 26);
        return (p, const Offset(38, 6));
      case ZEmptyArt.bubble:
        final p = Path()
          ..moveTo(15, 33)
          ..lineTo(12, 41)
          ..lineTo(22, 33)
          ..lineTo(34, 33)
          ..quadraticBezierTo(41, 33, 41, 26)
          ..lineTo(41, 16)
          ..quadraticBezierTo(41, 9, 34, 9)
          ..lineTo(14, 9)
          ..quadraticBezierTo(7, 9, 7, 16)
          ..lineTo(7, 26)
          ..quadraticBezierTo(7, 33, 15, 33)
          ..moveTo(15, 21)
          ..lineTo(33, 21);
        return (p, const Offset(42, 5));
      case null:
        final p = Path()
          ..addArc(Rect.fromCircle(center: const Offset(24, 24), radius: 20), 0.4, 5.6);
        return (p, const Offset(41, 9));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 48;
    canvas.save();
    canvas.scale(scale);
    final (path, lift) = _shape();
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75 / scale // 1.75 logical px after the canvas scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * progress.clamp(0.0, 1.0);
    for (final m in metrics) {
      if (remaining <= 0) break;
      final len = remaining < m.length ? remaining : m.length;
      canvas.drawPath(m.extractPath(0, len), paint);
      remaining -= len;
    }

    if (dotScale > 0) {
      canvas.drawCircle(lift, 3 * dotScale, Paint()..color = spark);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PenPainter old) =>
      old.art != art ||
      old.progress != progress ||
      old.dotScale != dotScale ||
      old.ink != ink ||
      old.spark != spark;
}
