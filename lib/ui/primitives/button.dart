import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';
import 'spinner.dart';

enum ZButtonVariant { filled, tonal, plain, danger }

/// sm 32px (inline actions, chips), md 40px (default), lg 48px (the one
/// primary call to action on a screen, e.g. sign in).
enum ZButtonSize { sm, md, lg }

/// Filled / tonal / plain / danger button with press-scale feedback.
/// `onPressed == null` disables the button. Set [expand] to fill the
/// available width (form buttons).
class ZButton extends StatelessWidget {
  const ZButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ZButtonVariant.filled,
    this.size = ZButtonSize.md,
    this.leading,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ZButtonVariant variant;
  final ZButtonSize size;
  final IconData? leading;
  final bool loading;
  final bool expand;

  bool get _disabled => onPressed == null || loading;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    // Text on a soft or clear background uses accentText: the deep Hibiscus
    // fill is too dark to read as text on near-black (BRAND.md s.3).
    final (bg, fg) = switch (variant) {
      ZButtonVariant.filled => (z.accent, z.onAccent),
      ZButtonVariant.tonal => (z.accentSoft, z.accentText),
      ZButtonVariant.plain => (Colors.transparent, z.accentText),
      ZButtonVariant.danger => (z.danger, z.onAccent),
    };
    final effBg = _disabled && bg != Colors.transparent ? bg.withValues(alpha: 0.4) : bg;
    final effFg = _disabled ? fg.withValues(alpha: 0.4) : fg;

    final height = switch (size) {
      ZButtonSize.sm => 32.0,
      ZButtonSize.md => 40.0,
      ZButtonSize.lg => 48.0,
    };
    final hPad = size == ZButtonSize.sm ? ZSpace.s12 : ZSpace.s16;
    final baseStyle = size == ZButtonSize.sm ? context.type.labelLarge : context.type.bodyLarge;
    final textStyle = size == ZButtonSize.lg && baseStyle != null
        ? ZType.withWeight(baseStyle, FontWeight.w500)
        : baseStyle;
    final radius = size == ZButtonSize.lg ? ZRadius.lg : ZRadius.md;

    final button = Pressable(
      onTap: _disabled ? null : onPressed,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: ZMotion.medium,
        curve: ZMotion.standard,
        height: height,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        decoration: BoxDecoration(
          color: effBg,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              ZSpinner(size: 14, color: effFg),
              const SizedBox(width: ZSpace.s8),
            ] else if (leading != null) ...[
              Icon(leading, size: 16, color: effFg),
              const SizedBox(width: ZSpace.s8),
            ],
            Text(label, maxLines: 1, style: textStyle?.copyWith(color: effFg)),
          ],
        ),
      ),
    );

    // Visual height stays compact (32/40), but md's tap target is widened to
    // the 48px minimum hit-area guideline; sm is left as-is, lg already is.
    if (size != ZButtonSize.md) return button;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Center(child: button),
    );
  }
}
