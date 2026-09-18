import 'package:flutter/material.dart';

import '../theme.dart';

/// Round initial avatar: the first letter of [name] in Hibiscus text on the
/// soft Hibiscus fill (accentText on accentSoft is AA in both themes).
class ZAvatar extends StatelessWidget {
  const ZAvatar({super.key, required this.name, this.size = ZLayout.avatarSm});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final style = size >= ZLayout.avatarLg ? context.type.titleMedium : context.type.labelLarge;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: z.accentSoft, shape: BoxShape.circle),
        child: Text(initial, style: style?.copyWith(color: z.accentText)),
      ),
    );
  }
}
