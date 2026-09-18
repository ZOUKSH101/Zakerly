import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:zakerly/core/animations.dart';
import 'package:zakerly/core/app_services.dart';
import 'package:zakerly/core/models.dart';
import 'package:zakerly/core/util.dart';

import '../../primitives/primitives.dart';
import 'html_frame.dart';

/// Opens a dialog that asks the model to draw an HTML animation of
/// [concept] for [course] (or serves it from the shared course cache), and
/// shows the result in a sandboxed [HtmlFrame].
Future<void> showAnimationWindow(
  BuildContext context, {
  required Course course,
  required String concept,
}) {
  return showZDialog(
    context,
    builder: (context) => _AnimationWindow(course: course, concept: concept),
  );
}

class _AnimationWindow extends StatefulWidget {
  const _AnimationWindow({required this.course, required this.concept});

  final Course course;
  final String concept;

  @override
  State<_AnimationWindow> createState() => _AnimationWindowState();
}

class _AnimationWindowState extends State<_AnimationWindow> {
  late final Future<AnimationResult> _future;
  int _replay = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Services.of uses getInheritedWidgetOfExactType, which is safe here.
    _future = Services.of(context).animations.visualize(widget.course, widget.concept);
    _future.then((_) {
      if (mounted) setState(() => _loaded = true);
    }).catchError((_) {
      // Swallow: the FutureBuilder below renders the error state.
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Animation: ${widget.concept}',
      child: ZDialogFrame(
        title: widget.concept,
        subtitle: '${widget.course.code} · ${widget.course.name}',
        width: math.max(0.0, math.min(1280.0, size.width - 2 * ZSpace.s24)),
        height: math.max(0.0, math.min(880.0, size.height - 2 * ZSpace.s24)),
        actions: [
          ZIconButton(
            icon: Icons.replay,
            tooltip: 'Replay',
            onPressed: _loaded ? () => setState(() => _replay++) : null,
          ),
        ],
        child: FutureBuilder<AnimationResult>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              final z = context.z;
              return Semantics(
                liveRegion: true,
                excludeSemantics: true,
                label: 'Drawing your animation. Checking if your class already has one',
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ZSpinner(size: 24),
                      const SizedBox(height: ZSpace.s16),
                      Text(
                        'Drawing your animation…',
                        style: context.type.bodyLarge?.copyWith(color: z.text),
                      ),
                      const SizedBox(height: ZSpace.s4),
                      Text(
                        'Checking if your class already has one',
                        style: context.type.bodySmall?.copyWith(color: z.textTertiary),
                      ),
                    ],
                  ),
                ),
              );
            }
            final error = snapshot.error;
            if (error != null) {
              if (error is AnimationLimitReached) {
                return Semantics(
                  liveRegion: true,
                  child: ZEmpty(
                    icon: Icons.hourglass_empty,
                    title: 'That\'s all for today',
                    message: error.message,
                    action: const ZBadge(label: 'Pro: 100 a day', tone: ZBadgeTone.accent),
                  ),
                );
              }
              return Semantics(
                liveRegion: true,
                child: const ZEmpty(
                  icon: Icons.error_outline,
                  title: "Couldn't draw that",
                  message: 'Try again, or ask the question a different way.',
                ),
              );
            }
            final result = snapshot.data!;
            return _Result(course: widget.course, result: result, replayKey: _replay);
          },
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.course, required this.result, required this.replayKey});

  final Course course;
  final AnimationResult result;
  final int replayKey;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Semantics(
            liveRegion: true,
            child: Row(
              children: [
                if (result.fromCache)
                  ZBadge(
                    tone: ZBadgeTone.success,
                    icon: Icons.bolt,
                    label: 'Saved ${formatTokens(result.tokens)} tokens',
                  )
                else
                  ZBadge(
                    tone: ZBadgeTone.accent,
                    icon: Icons.auto_awesome,
                    label: 'Used ${formatTokens(result.tokens)} tokens',
                  ),
                const SizedBox(width: ZSpace.s8),
                Flexible(
                  child: Text(
                    result.fromCache
                        ? 'Already drawn for your class'
                        : 'Now free for everyone in ${course.code}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.bodySmall?.copyWith(color: z.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ZSpace.s12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ZRadius.md),
            child: HtmlFrame(
              key: ValueKey(Object.hash(replayKey, result.html)),
              title: 'Animation: ${result.concept}',
              html: result.html,
            ),
          ),
        ),
      ],
    );
  }
}
