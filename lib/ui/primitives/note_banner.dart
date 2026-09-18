import 'package:flutter/material.dart';

import '../theme.dart';

/// A quiet inline note: icon, one short sentence and an optional action,
/// on the raised2 fill. For "getting ready" and plan-limit notes.
class ZNoteBanner extends StatelessWidget {
  const ZNoteBanner({super.key, required this.text, this.icon = Icons.hourglass_bottom, this.action});

  final String text;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ZSpace.s16, vertical: ZSpace.s12),
      decoration: BoxDecoration(
        color: z.raised2,
        borderRadius: BorderRadius.circular(ZRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: ZIcon.md, color: z.textSecondary),
          const SizedBox(width: ZSpace.s12),
          Expanded(
            child: Text(text, style: context.type.bodySmall?.copyWith(color: z.textSecondary)),
          ),
          if (action != null) ...[const SizedBox(width: ZSpace.s12), action!],
        ],
      ),
    );
  }
}
