import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../theme.dart';
import 'icon_button.dart';

/// Shows a dialog whose entrance scales 0.8333 -> 1.0 with the overshoot
/// curve over [ZMotion.enter] (500ms), and whose exit takes [ZMotion.exit]
/// (150ms), scaling 1.0 -> 1.2 while fading out. With reduced motion the
/// dialog simply fades, with no scale or overshoot. Barrier is black @ 45%.
Future<T?> showZDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return Navigator.of(context, rootNavigator: true).push<T>(
    _ZDialogRoute<T>(
      barrierDismissible: dismissible,
      barrierColor: const Color(0x73000000), // black @ 45%
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: reduced ? ZMotion.exit : ZMotion.enter,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        if (reduced) return FadeTransition(opacity: animation, child: child);
        final curved = CurvedAnimation(
          parent: animation,
          curve: ZMotion.overshoot,
          reverseCurve: ZMotion.exitCurve,
        );
        return AnimatedBuilder(
          animation: curved,
          builder: (context, _) {
            final reversing = animation.status == AnimationStatus.reverse;
            final v = curved.value;
            final scale = reversing ? (1.0 + 0.2 * (1 - v)) : (0.8333 + 0.1667 * v);
            return Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: child,
        );
      },
    ),
  );
}

/// A [RawDialogRoute] whose exit lasts [ZMotion.exit], so the route stops
/// blocking input as soon as its content is gone.
class _ZDialogRoute<T> extends RawDialogRoute<T> {
  _ZDialogRoute({
    required super.pageBuilder,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.transitionDuration,
    super.transitionBuilder,
  });

  @override
  Duration get reverseTransitionDuration => ZMotion.exit;
}

/// Standard dialog shell:raised background, xl radius, header row with
/// title (+ optional subtitle) and a close button, a hairline divider, then
/// the body and optional trailing actions.
class ZDialogFrame extends StatelessWidget {
  const ZDialogFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.child,
    this.width = 480,
    this.height = 360,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: z.raised,
            borderRadius: BorderRadius.circular(ZRadius.xl),
            border: Border.all(color: z.hairline),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(ZSpace.s20, ZSpace.s16, ZSpace.s12, ZSpace.s16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: context.type.titleMedium?.copyWith(color: z.text)),
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
                    ZIconButton(
                      icon: Icons.close,
                      tooltip: S.of(context).close,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: z.hairline),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(ZSpace.s20),
                  child: child,
                ),
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(ZSpace.s20, ZSpace.s8, ZSpace.s20, ZSpace.s16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: ZSpace.s8),
                        actions[i],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
