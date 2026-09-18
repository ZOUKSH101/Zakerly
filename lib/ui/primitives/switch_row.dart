import 'package:flutter/material.dart';

import '../theme.dart';

/// A row with a title (and optional subtitle) plus a trailing [Switch].
/// `onChanged == null` disables the row.
class ZSwitchRow extends StatelessWidget {
  const ZSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final disabled = onChanged == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: context.type.bodyLarge?.copyWith(color: z.text)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: context.type.bodySmall?.copyWith(color: z.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
