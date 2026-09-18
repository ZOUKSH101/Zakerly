// The spotlight coach-mark overlay: a dark scrim over the whole app with a
// rounded cutout around one real widget, and a tooltip bubble next to it.
// Inserted as an [OverlayEntry] on the root overlay so it sits above
// everything, including any open dialogs.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../l10n/strings.dart';
import '../../primitives/primitives.dart';
import 'tutorial_copy.dart';

/// Inserts the spotlight overlay and returns a future that completes once
/// the tour is dismissed (Skip, Done, Escape, or running out of steps).
Future<void> showSpotlightTutorial(BuildContext context) {
  final overlayState = Overlay.of(context, rootOverlay: true);
  final completer = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _HitTestGate(
      child: _TutorialOverlay(
        onDone: () {
          if (entry.mounted) entry.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    ),
  );
  overlayState.insert(entry);
  return completer.future;
}

enum _Side { top, bottom, left, right }

/// Lets the tour hit-test the app underneath it: while [_RenderHitTestGate.open]
/// is set, the overlay reports no hit, so a hit test at a target's centre
/// reaches whatever is really there.
class _HitTestGate extends SingleChildRenderObjectWidget {
  const _HitTestGate({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHitTestGate();
}

class _RenderHitTestGate extends RenderProxyBox {
  static bool open = false;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (open) return false;
    return super.hitTest(result, position: position);
  }
}

class _TutorialOverlay extends StatefulWidget {
  const _TutorialOverlay({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay> with WidgetsBindingObserver {
  int _index = 0;

  /// False until the first post-frame check; nothing is drawn before then.
  bool _ready = false;

  /// For each step, the key it lights up (its target, or a fallback), or
  /// nothing if no key is visible and hittable. Refreshed by [_resolve],
  /// which hit-tests, so only after the overlay has been laid out.
  final Map<int, GlobalKey> _resolved = {};

  final FocusScopeNode _scopeNode = FocusScopeNode(debugLabel: 'tutorial.scope');
  final FocusNode _focusNode = FocusNode(debugLabel: 'tutorial.overlay');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Targets are measured and hit-tested after the first frame, once this
    // overlay has a size of its own.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resolve();
      final start = _firstValidFrom(0);
      if (start == -1) {
        // Nothing is visible (e.g. every panel is hidden on a very narrow
        // screen): bail out instead of showing an empty scrim.
        widget.onDone();
        return;
      }
      setState(() {
        _index = start;
        _ready = true;
      });
      // Grab keyboard focus explicitly: the overlay is inserted directly
      // (not pushed as a route), so whatever was focused before it opened
      // (e.g. the button that triggered it) would otherwise keep it.
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Window resized — a target may have appeared, disappeared, or moved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ready) return;
      _resolve();
      setState(() {
        if (!_isValid(_index)) {
          final next = _firstValidFrom(_index);
          if (next == -1) {
            widget.onDone();
          } else {
            _index = next;
          }
        }
      });
    });
  }

  static RenderBox? _boxFor(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (box.size.width <= 0 || box.size.height <= 0) return null;
    return box;
  }

  static Rect? _rectFor(GlobalKey key) {
    final box = _boxFor(key);
    if (box == null) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  /// Whether a pointer at the target actually reaches its RenderBox. This
  /// rules out targets that are mounted and sized but not really on screen:
  /// a hidden IndexedStack tab, an Offstage panel, something off-screen or
  /// under another layer. Samples the centre and four inner points, so a
  /// target with an empty gap in its middle still counts.
  bool _reachable(GlobalKey key) {
    final box = _boxFor(key);
    final ctx = key.currentContext;
    if (box == null || ctx == null) return false;
    final view = View.maybeOf(ctx);
    if (view == null) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final points = [
      rect.center,
      Offset(rect.left + rect.width * 0.25, rect.top + rect.height * 0.25),
      Offset(rect.left + rect.width * 0.75, rect.top + rect.height * 0.25),
      Offset(rect.left + rect.width * 0.25, rect.top + rect.height * 0.75),
      Offset(rect.left + rect.width * 0.75, rect.top + rect.height * 0.75),
    ];
    _RenderHitTestGate.open = true;
    try {
      for (final p in points) {
        final result = HitTestResult();
        WidgetsBinding.instance.hitTestInView(result, p, view.viewId);
        if (result.path.any((e) => identical(e.target, box))) return true;
      }
      return false;
    } finally {
      _RenderHitTestGate.open = false;
    }
  }

  void _resolve() {
    _resolved.clear();
    final steps = tutorialSteps;
    for (var i = 0; i < steps.length; i++) {
      for (final key in steps[i].keys) {
        if (_reachable(key)) {
          _resolved[i] = key;
          break;
        }
      }
    }
  }

  Rect? _stepRect(int i) {
    final key = _resolved[i];
    return key == null ? null : _rectFor(key);
  }

  bool _isValid(int i) => _stepRect(i) != null;

  int _firstValidFrom(int start) {
    final total = tutorialSteps.length;
    for (var step = 0; step < total; step++) {
      final i = (start + step) % total;
      if (_isValid(i)) return i;
    }
    return -1;
  }

  List<int> get _visibleIndexes => [
    for (var i = 0; i < tutorialSteps.length; i++)
      if (_isValid(i)) i,
  ];

  /// Keeps keyboard focus inside the tour after a pointer tap on one of its
  /// buttons or the scrim (which would otherwise leave nothing focused, so
  /// the arrow keys stop working). Leaves a keyboard-focused button alone.
  void _keepFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_scopeNode.hasFocus) _focusNode.requestFocus();
    });
  }

  void _next() {
    _resolve();
    final visible = _visibleIndexes;
    final pos = visible.indexOf(_index);
    if (pos == -1 || pos == visible.length - 1) {
      widget.onDone();
      return;
    }
    setState(() => _index = visible[pos + 1]);
    _keepFocus();
  }

  void _back() {
    _resolve();
    final visible = _visibleIndexes;
    final pos = visible.indexOf(_index);
    if (pos <= 0) return;
    setState(() => _index = visible[pos - 1]);
    _keepFocus();
  }

  void _skip() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    if (!_ready || !_isValid(_index)) return const SizedBox.shrink();

    final z = context.z;
    final t = S.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final screen = MediaQuery.sizeOf(context);
    final target = _stepRect(_index)!.inflate(8);
    final visible = _visibleIndexes;
    final pos = visible.indexOf(_index);
    final step = tutorialStepsFor(t)[_index];
    final isLast = pos == visible.length - 1;
    // "Forward" follows the reading direction: the right arrow in English,
    // the left arrow in Arabic.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final side = _bestSide(target, screen, rtl: rtl);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _skip,
        const SingleActivator(LogicalKeyboardKey.enter): _next,
        const SingleActivator(LogicalKeyboardKey.arrowRight): rtl ? _back : _next,
        const SingleActivator(LogicalKeyboardKey.arrowDown): _next,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): rtl ? _next : _back,
        const SingleActivator(LogicalKeyboardKey.arrowUp): _back,
      },
      // A focus scope of its own: Tab cycles through the bubble's buttons
      // and never reaches the app under the scrim. BlockSemantics hides that
      // app from screen readers for the same reason.
      child: FocusScope(
        node: _scopeNode,
        autofocus: true,
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: BlockSemantics(
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              liveRegion: true,
              label: t.tutorialSemantics(pos + 1, visible.length, step.title, step.body),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _next,
                    child: TweenAnimationBuilder<Rect?>(
                      tween: RectTween(begin: target, end: target),
                      duration: reduced ? Duration.zero : ZMotion.medium,
                      curve: ZMotion.standard,
                      builder: (context, animatedRect, _) {
                        return CustomPaint(
                          painter: _ScrimPainter(
                            cutout: animatedRect ?? target,
                            glow: z.accent,
                            scrim: z.scrim,
                          ),
                        );
                      },
                    ),
                  ),
                  _TooltipBubble(
                    target: target,
                    screen: screen,
                    side: side,
                    title: step.title,
                    body: step.body,
                    stepNumber: pos + 1,
                    stepTotal: visible.length,
                    isLast: isLast,
                    canGoBack: pos > 0,
                    onNext: _next,
                    onBack: _back,
                    onSkip: _skip,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The side of [target] with the most room. Placement is physical (it is
/// about screen space), but a tie between left and right goes to the
/// reading direction's "after" side: right in LTR, left in RTL.
_Side _bestSide(Rect target, Size screen, {bool rtl = false}) {
  final spaceTop = target.top;
  final spaceBottom = screen.height - target.bottom;
  final spaceLeft = target.left;
  final spaceRight = screen.width - target.right;
  final maxSpace = [spaceTop, spaceBottom, spaceLeft, spaceRight].reduce(math.max);
  if (maxSpace == spaceBottom) return _Side.bottom;
  if (maxSpace == spaceTop) return _Side.top;
  if (rtl) return maxSpace == spaceLeft ? _Side.left : _Side.right;
  if (maxSpace == spaceRight) return _Side.right;
  return _Side.left;
}

/// Paints the [scrim] (`z.scrim`, ~70% black in both themes) with a
/// rounded-rect hole over [cutout], plus a soft glow ring in the accent
/// color around the hole's edge.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.cutout, required this.glow, required this.scrim});

  final Rect cutout;
  final Color glow;
  final Color scrim;

  static const _radius = Radius.circular(ZRadius.lg);

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(RRect.fromRectAndRadius(cutout, _radius));
    final scrimPath = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(scrimPath, Paint()..color = scrim);

    final glowRRect = RRect.fromRectAndRadius(cutout, _radius);
    canvas.drawRRect(
      glowRRect,
      Paint()
        ..color = glow.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter oldDelegate) {
    return oldDelegate.cutout != cutout || oldDelegate.glow != glow || oldDelegate.scrim != scrim;
  }
}

/// The tooltip bubble: placed on the side of [target] with the most room,
/// clamped to stay fully on screen, with an arrow pointing back at the
/// target.
class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({
    required this.target,
    required this.screen,
    required this.side,
    required this.title,
    required this.body,
    required this.stepNumber,
    required this.stepTotal,
    required this.isLast,
    required this.canGoBack,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final Rect target;
  final Size screen;
  final _Side side;
  final String title;
  final String body;
  final int stepNumber;
  final int stepTotal;
  final bool isLast;
  final bool canGoBack;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: _BubbleLayoutDelegate(target: target, side: side),
      child: _BubbleCard(
        side: side,
        title: title,
        body: body,
        stepNumber: stepNumber,
        stepTotal: stepTotal,
        isLast: isLast,
        canGoBack: canGoBack,
        onNext: onNext,
        onBack: onBack,
        onSkip: onSkip,
      ),
    );
  }
}

class _BubbleLayoutDelegate extends SingleChildLayoutDelegate {
  _BubbleLayoutDelegate({required this.target, required this.side});

  final Rect target;
  final _Side side;

  static const double gap = 16;
  static const double margin = 12;
  static const double maxWidth = 300;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(maxWidth, constraints.maxWidth - margin * 2);
    return BoxConstraints(maxWidth: math.max(0, width));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double dx, dy;
    switch (side) {
      case _Side.bottom:
        dy = target.bottom + gap;
        dx = target.center.dx - childSize.width / 2;
      case _Side.top:
        dy = target.top - gap - childSize.height;
        dx = target.center.dx - childSize.width / 2;
      case _Side.right:
        dx = target.right + gap;
        dy = target.center.dy - childSize.height / 2;
      case _Side.left:
        dx = target.left - gap - childSize.width;
        dy = target.center.dy - childSize.height / 2;
    }
    final maxDx = math.max(margin, size.width - childSize.width - margin);
    final maxDy = math.max(margin, size.height - childSize.height - margin);
    return Offset(dx.clamp(margin, maxDx), dy.clamp(margin, maxDy));
  }

  @override
  bool shouldRelayout(covariant _BubbleLayoutDelegate oldDelegate) {
    return oldDelegate.target != target || oldDelegate.side != side;
  }
}

class _BubbleCard extends StatelessWidget {
  const _BubbleCard({
    required this.side,
    required this.title,
    required this.body,
    required this.stepNumber,
    required this.stepTotal,
    required this.isLast,
    required this.canGoBack,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final _Side side;
  final String title;
  final String body;
  final int stepNumber;
  final int stepTotal;
  final bool isLast;
  final bool canGoBack;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final t = S.of(context);

    // Arrow sits just outside the card, on the edge nearest the target,
    // pointing back at it.
    final (arrowAlign, arrowShift, arrowSize) = switch (side) {
      _Side.bottom => (Alignment.topCenter, const Offset(0, -1), const Size(16, 8)),
      _Side.top => (Alignment.bottomCenter, const Offset(0, 1), const Size(16, 8)),
      _Side.right => (Alignment.centerLeft, const Offset(-1, 0), const Size(8, 16)),
      _Side.left => (Alignment.centerRight, const Offset(1, 0), const Size(8, 16)),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ZCard(
          padding: ZSpace.s16,
          // No live region here: the overlay's own Semantics already
          // announces each step; a nested one read it twice.
          child: Semantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.stepOf(stepNumber, stepTotal),
                  style: context.type.labelSmall?.copyWith(color: z.textSecondary),
                ),
                const SizedBox(height: ZSpace.s4),
                Text(title, style: context.type.titleMedium?.copyWith(color: z.text)),
                const SizedBox(height: ZSpace.s4),
                Text(body, style: context.type.bodyMedium?.copyWith(color: z.textSecondary)),
                const SizedBox(height: ZSpace.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isLast)
                      ZButton(
                        label: t.skip,
                        variant: ZButtonVariant.plain,
                        size: ZButtonSize.sm,
                        onPressed: onSkip,
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        if (canGoBack) ...[
                          ZButton(
                            label: t.back,
                            variant: ZButtonVariant.tonal,
                            size: ZButtonSize.sm,
                            onPressed: onBack,
                          ),
                          const SizedBox(width: ZSpace.s8),
                        ],
                        ZButton(label: isLast ? t.done : t.next, size: ZButtonSize.sm, onPressed: onNext),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: arrowAlign,
            child: FractionalTranslation(
              translation: arrowShift,
              child: CustomPaint(
                size: arrowSize,
                painter: _ArrowPainter(side: side, fill: z.raised, border: z.hairline),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small triangle pointing away from the bubble, toward the target.
class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.side, required this.fill, required this.border});

  final _Side side;
  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    switch (side) {
      case _Side.bottom: // arrow at top of card, pointing up
        path
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height);
      case _Side.top: // arrow at bottom of card, pointing down
        path
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0);
      case _Side.right: // arrow at left of card, pointing left
        path
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height);
      case _Side.left: // arrow at right of card, pointing right
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.side != side || oldDelegate.fill != fill || oldDelegate.border != border;
  }
}
