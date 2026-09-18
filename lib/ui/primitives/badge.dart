import 'package:flutter/material.dart';

import '../theme.dart';

enum ZBadgeTone { neutral, accent, success, warning, danger }

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
      ZBadgeTone.accent => (z.accentSoft, z.accent),
      ZBadgeTone.success => (z.success.withValues(alpha: 0.16), z.success),
      ZBadgeTone.warning => (z.warning.withValues(alpha: 0.16), z.warning),
      ZBadgeTone.danger => (z.danger.withValues(alpha: 0.16), z.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ZSpace.s8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(ZRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
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
