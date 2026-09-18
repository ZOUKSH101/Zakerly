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
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final disabled = onPressed == null;
    final bg = selected ? z.accentSoft : Colors.transparent;
    final fg = selected ? z.accent : z.textSecondary;

    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: disabled ? null : onPressed,
        child: AnimatedContainer(
          duration: ZMotion.medium,
          curve: ZMotion.standard,
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(ZRadius.sm)),
          child: Icon(icon, size: 18, color: disabled ? fg.withValues(alpha: 0.4) : fg),
        ),
      ),
    );
  }
}
