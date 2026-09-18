import 'package:flutter/material.dart';

import '../theme.dart';

/// Small circular progress indicator, sized and colored from tokens.
class ZSpinner extends StatelessWidget {
  const ZSpinner({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size / 8,
        color: color ?? context.z.accent,
      ),
    );
  }
}
