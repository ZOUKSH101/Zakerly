// The onboarding sheet itself: a centered card with 4-5 pages, dots,
// Next/Back/Skip and a keyboard-friendly, motion-aware transition between
// pages. Composed entirely from lib/ui/primitives + theme tokens.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../primitives/primitives.dart';
import 'tutorial_pages.dart';

class TutorialSheet extends StatefulWidget {
  const TutorialSheet({super.key});

  @override
  State<TutorialSheet> createState() => _TutorialSheetState();
}

class _TutorialSheetState extends State<TutorialSheet> {
  int _index = 0;
  int _direction = 1; // 1 = advancing (Next), -1 = retreating (Back).

  bool get _isLast => _index == tutorialPages.length - 1;

  void _next() {
    if (_isLast) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _direction = 1;
      _index++;
    });
  }

  void _back() {
    if (_index == 0) return;
    setState(() {
      _direction = -1;
      _index--;
    });
  }

  void _skip() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final total = tutorialPages.length;
    final page = tutorialPages[_index];

    final actions = <Widget>[
      if (!_isLast)
        ZButton(
          label: 'Skip',
          variant: ZButtonVariant.plain,
          size: ZButtonSize.sm,
          onPressed: _skip,
        ),
      if (_index > 0)
        ZButton(
          label: 'Back',
          variant: ZButtonVariant.tonal,
          size: ZButtonSize.sm,
          onPressed: _back,
        ),
      ZButton(
        label: _isLast ? 'Get started' : 'Next',
        size: ZButtonSize.sm,
        onPressed: _next,
      ),
    ];

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Welcome to Zakerly, page ${_index + 1} of $total',
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _skip,
          const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _back,
        },
        child: Focus(
          autofocus: true,
          child: ZDialogFrame(
            title: 'Welcome to Zakerly',
            subtitle: 'Step ${_index + 1} of $total',
            width: 440,
            height: 440,
            actions: actions,
            child: Column(
              children: [
                Expanded(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: reduced ? Duration.zero : ZMotion.medium,
                      switchInCurve: ZMotion.standard,
                      switchOutCurve: ZMotion.exitCurve,
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: Offset(_direction * 0.08, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_index),
                        child: _TutorialPageBody(page: page),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ZSpace.s16),
                _Dots(count: total, index: _index),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialPageBody extends StatelessWidget {
  const _TutorialPageBody({required this.page});

  final TutorialPageData page;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Illustration(icons: page.icons),
          const SizedBox(height: ZSpace.s24),
          Text(
            page.headline,
            textAlign: TextAlign.center,
            style: context.type.titleLarge?.copyWith(color: z.text),
          ),
          const SizedBox(height: ZSpace.s8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZSpace.s16),
            child: Text(
              page.body,
              textAlign: TextAlign.center,
              style: context.type.bodyMedium?.copyWith(color: z.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small widget-built illustration: a soft accent circle behind one or two
/// icons. No image assets, no new tokens — just [ZTokens] colors.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.icons});

  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return ExcludeSemantics(
      child: SizedBox(
        height: 96,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: z.accentSoft, shape: BoxShape.circle),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons.first, size: 36, color: z.accent),
                  if (icons.length > 1) ...[
                    const SizedBox(width: ZSpace.s12),
                    Icon(icons[1], size: 28, color: z.accent.withValues(alpha: 0.55)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Semantics(
      label: 'Page ${index + 1} of $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: ZMotion.medium,
              curve: ZMotion.standard,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 8 : 6,
              height: i == index ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == index ? z.accent : z.raised2,
              ),
            ),
        ],
      ),
    );
  }
}
