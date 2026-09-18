import 'package:flutter/material.dart';

import '../theme.dart';

/// Small section label with a touch of extra letter-spacing. Renders
/// [label] as given — callers choose the casing; this does not force
/// upper-case, which reads as shouting rather than an Apple-style kicker.
class ZEyebrow extends StatelessWidget {
  const ZEyebrow(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final base = context.type.labelSmall;
    return Text(
      label,
      style: base?.copyWith(
        color: z.textSecondary,
        fontWeight: FontWeight.w500,
        letterSpacing: (base.letterSpacing ?? 0) + 0.3,
      ),
    );
  }
}
