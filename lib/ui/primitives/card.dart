import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';

/// Raised surface, Apple card style: generous inner padding, a large
/// corner radius, and no hairline in light mode — separation there comes
/// from [ZTokens.raised] sitting on [ZTokens.surface] plus a soft shadow.
/// Dark mode has no shadow (Apple casts elevation shadow in light mode
/// only) so it keeps a hairline for definition instead. Optionally tappable
/// with press-scale feedback.
class ZCard extends StatelessWidget {
  const ZCard({
    super.key,
    required this.child,
    this.padding = ZLayout.panelPadding,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = selected
        ? Border.all(color: z.accent, width: 1.5)
        : (isDark ? Border.all(color: z.hairline) : null);
    final content = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: z.raised,
        borderRadius: BorderRadius.circular(ZRadius.card),
        border: border,
        boxShadow: ZShadow.card(Theme.of(context).brightness),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Pressable(onTap: onTap, child: content);
  }
}
