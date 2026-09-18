import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';

/// Compact list row: leading/title/subtitle/trailing, dense (44px min
/// height), optionally tappable.
class ZRow extends StatelessWidget {
  const ZRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZSpace.s12, vertical: ZSpace.s8),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: ZSpace.s12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.type.bodyLarge?.copyWith(color: z.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: context.type.bodySmall?.copyWith(color: z.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: ZSpace.s12),
              trailing!,
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return Pressable(onTap: onTap, child: content);
  }
}
