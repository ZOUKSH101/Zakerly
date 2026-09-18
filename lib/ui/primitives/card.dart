import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';

/// Raised surface with a hairline border and large radius. Optionally
/// tappable with press-scale feedback.
class ZCard extends StatelessWidget {
  const ZCard({
    super.key,
    required this.child,
    this.padding = 16,
    this.onTap,
    this.selected = false,
  });

  final Widget child;
  final double padding;
  final VoidCallback? onTap;
  /// When true, draws an accent border (same radius) instead of the hairline.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final content = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: z.raised,
        borderRadius: BorderRadius.circular(ZRadius.lg),
        border: Border.all(color: selected ? z.accent : z.hairline, width: selected ? 1.5 : 1),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Pressable(onTap: onTap, child: content);
  }
}
