import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';

/// Compact icon-only button. `tooltip` is required for accessibility.
class ZIconButton extends StatelessWidget {
  const ZIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.mirrorInRtl = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  /// Flip the glyph horizontally in right-to-left layouts, for icons that
  /// point "forward" (the reading direction) rather than at a fixed side.
  final bool mirrorInRtl;

  /// Edge of the tappable area (the visible chip is [ZLayout.iconButtonSize]).
  static const double hitSize = 44;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final disabled = onPressed == null;
    final bg = selected ? z.accentSoft : Colors.transparent;
    final fg = selected ? z.accentText : z.textSecondary;
    Widget glyph = Icon(icon, size: 18, color: disabled ? fg.withValues(alpha: 0.4) : fg);
    if (mirrorInRtl && Directionality.of(context) == TextDirection.rtl) {
      glyph = Transform.flip(flipX: true, child: glyph);
    }

    // The visible chip stays 32px; the hit target around it is 44px.
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: disabled ? null : onPressed,
        child: SizedBox.square(
          dimension: ZIconButton.hitSize,
          child: Center(
            child: AnimatedContainer(
              duration: ZMotion.medium,
              curve: ZMotion.standard,
              width: ZLayout.iconButtonSize,
              height: ZLayout.iconButtonSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(ZRadius.sm)),
              child: glyph,
            ),
          ),
        ),
      ),
    );
  }
}
