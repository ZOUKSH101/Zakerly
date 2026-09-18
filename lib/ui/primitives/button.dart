import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';
import 'spinner.dart';

enum ZButtonVariant { filled, tonal, plain, danger }

enum ZButtonSize { sm, md }

/// Filled / tonal / plain / danger button with press-scale feedback.
/// `onPressed == null` disables the button.
class ZButton extends StatelessWidget {
  const ZButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ZButtonVariant.filled,
    this.size = ZButtonSize.md,
    this.leading,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ZButtonVariant variant;
  final ZButtonSize size;
  final IconData? leading;
  final bool loading;

  bool get _disabled => onPressed == null || loading;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final (bg, fg) = switch (variant) {
      ZButtonVariant.filled => (z.accent, z.onAccent),
      ZButtonVariant.tonal => (z.accentSoft, z.accent),
      ZButtonVariant.plain => (Colors.transparent, z.accent),
      ZButtonVariant.danger => (z.danger, z.onAccent),
    };
    final effBg = _disabled && bg != Colors.transparent ? bg.withValues(alpha: 0.4) : bg;
    final effFg = _disabled ? fg.withValues(alpha: 0.4) : fg;

    final height = size == ZButtonSize.sm ? 32.0 : 40.0;
    final hPad = size == ZButtonSize.sm ? ZSpace.s12 : ZSpace.s16;
    final textStyle = size == ZButtonSize.sm ? context.type.labelLarge : context.type.bodyLarge;

    final button = Pressable(
      onTap: _disabled ? null : onPressed,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: ZMotion.medium,
        curve: ZMotion.standard,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        decoration: BoxDecoration(
          color: effBg,
          borderRadius: BorderRadius.circular(ZRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              ZSpinner(size: 14, color: effFg),
              const SizedBox(width: ZSpace.s8),
            ] else if (leading != null) ...[
              Icon(leading, size: 16, color: effFg),
              const SizedBox(width: ZSpace.s8),
            ],
            Text(label, style: textStyle?.copyWith(color: effFg)),
          ],
        ),
      ),
    );

    // Visual height stays compact (32/40), but md's tap target is widened to
    // the 48px minimum hit-area guideline; sm is left as-is.
    if (size != ZButtonSize.md) return button;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Center(child: button),
    );
  }
}
