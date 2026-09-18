import 'package:flutter/material.dart';

import '../theme.dart';

/// A tiny numbered pill (the accent badge, at citation size). Sizes to its
/// number, never to the available width, so it can sit inline in running
/// text as a [WidgetSpan] and flow with the words.
class ZCiteMark extends StatelessWidget {
  const ZCiteMark({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final style = context.type.labelSmall;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: ZLayout.citeMarkSize,
        minHeight: ZLayout.citeMarkSize,
        maxHeight: ZLayout.citeMarkSize,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: z.accentSoft,
          borderRadius: BorderRadius.circular(ZRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ZSpace.s4),
          // widthFactor 1: as wide as the number, not as the line.
          child: Align(
            widthFactor: 1,
            child: Text(
              '$number',
              textAlign: TextAlign.center,
              style: style == null
                  ? null
                  : ZType.withWeight(style, FontWeight.w600).copyWith(
                      color: z.accentText,
                      height: 1,
                      letterSpacing: 0,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
