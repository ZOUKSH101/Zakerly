import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';

/// Compact iOS-style segmented control with a sliding thumb.
class ZSegmented<T> extends StatelessWidget {
  const ZSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.tooltips,
  });

  final List<(T value, String label)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Optional hover/long-press hint per segment, matched to [segments] by
  /// index. Missing or empty entries get no tooltip.
  final List<String>? tooltips;

  Widget _withTooltip(int i, Widget child) {
    final tips = tooltips;
    if (tips == null || i >= tips.length || tips[i].isEmpty) return child;
    return Tooltip(message: tips[i], child: child);
  }

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final index = segments.indexWhere((s) => s.$1 == selected);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: z.raised2, borderRadius: BorderRadius.circular(ZRadius.md)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return SizedBox(
            width: constraints.maxWidth,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: ZMotion.medium,
                  curve: ZMotion.standard,
                  left: width * (index < 0 ? 0 : index),
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: z.raised,
                      borderRadius: BorderRadius.circular(ZRadius.sm),
                      border: Border.all(color: z.hairline),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (i, seg) in segments.indexed)
                      SizedBox(
                        width: width,
                        child: _withTooltip(
                          i,
                          Pressable(
                            onTap: () => onChanged(seg.$1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Center(
                                child: Text(
                                  seg.$2,
                                  style: context.type.labelLarge?.copyWith(
                                    color: seg.$1 == selected ? z.text : z.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
