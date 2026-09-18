import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';

/// Rounded suggestion chip: a quiet pill on [ZTokens.raised] with a hairline,
/// an optional leading icon, and press-scale feedback. Hover warms the
/// border to Hibiscus. Used for starter prompts; one tap acts.
class ZChip extends StatefulWidget {
  const ZChip({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  State<ZChip> createState() => _ZChipState();
}

class _ZChipState extends State<ZChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final enabled = widget.onPressed != null;
    final fg = enabled ? z.text : z.textTertiary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Pressable(
        onTap: widget.onPressed,
        semanticLabel: widget.label,
        child: AnimatedContainer(
          duration: ZMotion.medium,
          curve: ZMotion.standard,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: ZSpace.s16),
          decoration: BoxDecoration(
            color: z.raised,
            borderRadius: BorderRadius.circular(ZRadius.pill),
            border: Border.all(
              color: _hover && enabled ? z.accent.withValues(alpha: 0.6) : z.hairline,
            ),
            boxShadow: ZShadow.card(Theme.of(context).brightness),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: ZIcon.md, color: enabled ? z.accentText : fg),
                const SizedBox(width: ZSpace.s8),
              ],
              Text(widget.label, style: context.type.labelLarge?.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
