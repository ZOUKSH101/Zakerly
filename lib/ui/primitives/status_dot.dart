import 'package:flutter/material.dart';

import '../theme.dart';

/// A small colored dot in a fixed square slot, for list rows that show a
/// state without words. Give it a [label] so screen readers (and hover)
/// still get the words.
class ZStatusDot extends StatelessWidget {
  const ZStatusDot({super.key, required this.color, this.label});

  final Color color;
  final String? label;

  static const double slot = ZLayout.statusDotSlot;

  @override
  Widget build(BuildContext context) {
    Widget dot = SizedBox.square(
      dimension: slot,
      child: Center(
        child: Container(
          width: ZLayout.statusDot,
          height: ZLayout.statusDot,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
    final l = label;
    if (l != null && l.isNotEmpty) {
      dot = Tooltip(message: l, child: Semantics(label: l, child: dot));
    }
    return dot;
  }
}
