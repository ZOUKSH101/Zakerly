import 'package:flutter/material.dart';

import '../theme.dart';

/// Centered empty-state placeholder: icon, title, optional message/action.
class ZEmpty extends StatelessWidget {
  const ZEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ZSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: z.textTertiary),
            const SizedBox(height: ZSpace.s12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.type.titleMedium?.copyWith(color: z.text),
            ),
            if (message != null) ...[
              const SizedBox(height: ZSpace.s4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.type.bodyMedium?.copyWith(color: z.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: ZSpace.s16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
