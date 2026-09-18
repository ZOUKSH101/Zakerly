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
    this.titleMaxLines = 1,
    this.tooltip,
  });

  /// Rendered height of a one-line row.
  static const double minExtent = 44;

  /// Vertical padding around the text, top plus bottom.
  static const double verticalPadding = ZSpace.s8 * 2;

  /// Width taken by the row's own padding and the gaps next to [leading]
  /// and [trailing] (not the widgets themselves).
  static double chromeWidth({bool leading = false, bool trailing = false}) =>
      ZSpace.s12 * 2 + (leading ? ZSpace.s12 : 0) + (trailing ? ZSpace.s12 : 0);

  final Widget? leading;
  final String title;

  /// Long titles wrap up to this many lines before ellipsizing.
  final int titleMaxLines;

  /// Optional hover text for the whole row (e.g. why it's waiting).
  final String? tooltip;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minExtent),
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
                    maxLines: titleMaxLines,
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
    if (tooltip != null && tooltip!.isNotEmpty) {
      content = Tooltip(message: tooltip!, child: content);
    }
    if (onTap == null) return content;
    return Pressable(onTap: onTap, child: content);
  }
}
