import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Frosted panel: backdrop blur 20 over raised@72% with a hairline border.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.radius = ZRadius.lg});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: z.raised.withValues(alpha: 0.72),
            border: Border.all(color: z.hairline),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}
