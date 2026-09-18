import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zakerly/core/animations.dart';
import 'package:zakerly/core/app_services.dart';
import 'package:zakerly/core/models.dart';
import 'package:zakerly/core/preferences.dart';
import 'package:zakerly/core/util.dart';
import 'package:zakerly/l10n/strings.dart';

import '../../primitives/primitives.dart';
import 'html_frame.dart';

/// Opens a dialog that asks the model to draw an HTML animation of
/// [concept] for [course] (or serves it from the shared course cache), and
/// shows the result in a sandboxed [HtmlFrame].
Future<void> showAnimationWindow(BuildContext context, {required Course course, required String concept}) {
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
  bool _started = false;
  int _replay = 0;
  bool _loaded = false;

  /// True from the moment the dialog starts to close. The iframe is a
  /// platform view: it ignores the exit fade and would linger over the chat
  /// as a ghost, so it's removed on the first frame of the exit instead.
  bool _closing = false;
  Animation<double>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
    final route = ModalRoute.of(context)?.animation;
    if (!identical(route, _route)) {
      _route?.removeStatusListener(_onRouteStatus);
      _route = route;
      _route?.addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    final closing = status == AnimationStatus.reverse || status == AnimationStatus.dismissed;
    if (closing != _closing && mounted) setState(() => _closing = closing);
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_onRouteStatus);
    super.dispose();
  }

  /// Starts the generation once, the first time dependencies are available:
  /// the document is drawn in the app's language and theme as they are
  /// when the window opens.
  void _start() {
    final language = S.of(context).isArabic ? AppLanguage.arabic : AppLanguage.english;
    final dark = Theme.of(context).brightness == Brightness.dark;
    _language = language;
    _future = Services.of(context).animations.visualize(
      widget.course,
      widget.concept,
      language: language,
      theme: dark ? AnimationTheme.dark : AnimationTheme.light,
    );
    _future
        .then((_) {
          if (mounted) setState(() => _loaded = true);
        })
        .catchError((_) {
          // Swallow: the FutureBuilder below renders the error state.
        });
  }

  late final AppLanguage _language;
  final HtmlFrameController _frame = HtmlFrameController();
  bool _playing = false;

  void _onFrameMessage(String message) {
    switch (message) {
      case AnimationMessages.escape:
        Navigator.of(context).maybePop();
      case AnimationMessages.playing:
        setState(() => _playing = true);
      case AnimationMessages.paused:
        setState(() => _playing = false);
    }
  }

  void _back() => _frame.send(AnimationMessages.back);
  void _next() => _frame.send(AnimationMessages.next);
  void _toggle() => _frame.send(AnimationMessages.toggle);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final t = S.of(context);
    final copy = AnimationCopy.of(_language);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final ready = _loaded && !_closing;
    // Flutter-side step controls: they drive the document by postMessage,
    // so the player works from the keyboard even while focus is out here.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        if (ready) ...{
          SingleActivator(LogicalKeyboardKey.arrowRight): rtl ? _back : _next,
          SingleActivator(LogicalKeyboardKey.arrowLeft): rtl ? _next : _back,
        },
      },
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: t.animationSemantics(widget.concept),
        child: ZDialogFrame(
          title: widget.concept,
          subtitle: '${widget.course.code} · ${widget.course.name}',
          width: math.max(0.0, math.min(1280.0, size.width - 2 * ZSpace.s24)),
          height: math.max(0.0, math.min(880.0, size.height - 2 * ZSpace.s24)),
          actions: [
            ZIconButton(
              icon: Icons.replay,
              tooltip: t.replay,
              onPressed: ready
                  ? () => setState(() {
                      _replay++;
                      _playing = false; // the fresh document starts paused
                    })
                  : null,
            ),
            const Spacer(),
            ZButton(
              label: copy.back,
              variant: ZButtonVariant.tonal,
              size: ZButtonSize.sm,
              onPressed: ready ? _back : null,
            ),
            ZButton(
              label: _playing ? copy.pause : copy.play,
              size: ZButtonSize.sm,
              onPressed: ready ? _toggle : null,
            ),
            ZButton(
              label: copy.next,
              variant: ZButtonVariant.tonal,
              size: ZButtonSize.sm,
              onPressed: ready ? _next : null,
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
                  label: t.drawingSemantics,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ZSpinner(size: 24),
                        const SizedBox(height: ZSpace.s16),
                        Text(t.drawing, style: context.type.bodyLarge?.copyWith(color: z.text)),
                        const SizedBox(height: ZSpace.s4),
                        Text(
                          t.checkingClass,
                          style: context.type.bodySmall?.copyWith(color: z.textSecondary),
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
                      title: t.limitTitle,
                      message: t.limitBody(error.perDay),
                      action: ZBadge(label: t.proPerDay, tone: ZBadgeTone.accent),
                    ),
                  );
                }
                return Semantics(
                  liveRegion: true,
                  child: ZEmpty(icon: Icons.error_outline, title: t.couldntDraw, message: t.couldntDrawBody),
                );
              }
              final result = snapshot.data!;
              return _Result(
                course: widget.course,
                result: result,
                replayKey: _replay,
                closing: _closing,
                language: _language,
                controller: _frame,
                onMessage: _onFrameMessage,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.course,
    required this.result,
    required this.replayKey,
    required this.closing,
    required this.language,
    required this.controller,
    required this.onMessage,
  });

  final Course course;
  final AnimationResult result;
  final int replayKey;
  final bool closing;
  final AppLanguage language;
  final HtmlFrameController controller;
  final ValueChanged<String> onMessage;

  static const _fromFrame = {AnimationMessages.escape, AnimationMessages.playing, AnimationMessages.paused};

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final t = S.of(context);
    final palette = AnimationPalette.of(
      Theme.of(context).brightness == Brightness.dark ? AnimationTheme.dark : AnimationTheme.light,
    );
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
                  // Delight #3: a cache hit wears the brand spark.
                  ZBadge(tone: ZBadgeTone.spark, label: t.savedTokens(formatTokens(result.tokens)))
                else
                  ZBadge(
                    tone: ZBadgeTone.accent,
                    icon: Icons.auto_awesome,
                    label: t.usedTokens(formatTokens(result.tokens)),
                  ),
                const SizedBox(width: ZSpace.s8),
                Flexible(
                  child: Text(
                    result.fromCache ? t.alreadyDrawn : t.nowFreeFor(course.code),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.bodySmall?.copyWith(color: z.textSecondary),
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
            child: closing
                ? ColoredBox(color: z.raised)
                : HtmlFrame(
                    key: ValueKey(Object.hash(replayKey, result.html)),
                    title: t.animationSemantics(result.concept),
                    html: result.html,
                    blockedDocument: blockedFrameDocument(
                      AnimationCopy.of(language).couldntShow,
                      lang: language.code,
                      rtl: language.isRtl,
                      background: palette.bg,
                      color: palette.muted,
                    ),
                    controller: controller,
                    onMessage: onMessage,
                    acceptedMessages: _fromFrame,
                  ),
          ),
        ),
      ],
    );
  }
}
