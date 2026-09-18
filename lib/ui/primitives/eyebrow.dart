import 'package:flutter/material.dart';

import '../theme.dart';

/// Small uppercase section label with extra letter-spacing.
class ZEyebrow extends StatelessWidget {
  const ZEyebrow(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final base = context.type.labelSmall;
    return Text(
      label.toUpperCase(),
      style: base?.copyWith(
        color: z.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: (base.letterSpacing ?? 0) + 0.6,
      ),
    );
  }
}
