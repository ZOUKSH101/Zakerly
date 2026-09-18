import 'package:flutter/material.dart';

import '../theme.dart';
import 'ring.dart';

/// Linear version of [ZRing]: same thresholds, animates value changes.
/// Give it a bounded width (e.g. via `Expanded`) when [width] is null.
class ZBar extends StatelessWidget {
  const ZBar({
    super.key,
    required this.fraction,
    this.height = 6,
    this.width,
    this.color,
  });

  final double fraction;
  final double height;
  final double? width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final clamped = fraction.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: ZMotion.medium,
      curve: ZMotion.standard,
      builder: (context, value, _) {
        return SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(color: z.raised2),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        width: constraints.maxWidth * value,
                        height: height,
                        color: ZRing.colorForFraction(z, value, override: color),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
