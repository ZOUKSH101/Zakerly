import 'package:flutter/material.dart';

import '../theme.dart';
import 'spark.dart';

/// [spark] is the amber delight tone (cache hits, finished work); it shows
/// the brand spark in place of an icon when no [ZBadge.icon] is given.
enum ZBadgeTone { neutral, accent, success, warning, danger, spark }

/// Compact pill label used for status/tone indicators.
class ZBadge extends StatelessWidget {
  const ZBadge({super.key, required this.label, this.tone = ZBadgeTone.neutral, this.icon});

  final String label;
  final ZBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final (bg, fg) = switch (tone) {
      ZBadgeTone.neutral => (z.raised2, z.textSecondary),
      ZBadgeTone.accent => (z.accentSoft, z.accentText),
      // The *Text tokens keep 11px labels at AA on the 16% tint.
      ZBadgeTone.success => (z.success.withValues(alpha: 0.16), z.successText),
      ZBadgeTone.warning => (z.warning.withValues(alpha: 0.16), z.warningText),
      ZBadgeTone.danger => (z.danger.withValues(alpha: 0.16), z.dangerText),
      ZBadgeTone.spark => (z.spark.withValues(alpha: 0.16), z.sparkText),
    };
    final Widget? leading = icon != null
        ? Icon(icon, size: 12, color: fg)
        : tone == ZBadgeTone.spark
            ? ZSparkGlyph(size: 12, color: z.spark)
            : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ZSpace.s8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(ZRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: ZSpace.s4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.labelSmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
