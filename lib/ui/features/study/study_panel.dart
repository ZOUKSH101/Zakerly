// Center column of the one-screen workspace: course header, chat thread and
// composer. The message list is the only scrolling area in the app.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:zakerly/core/app_services.dart';
import 'package:zakerly/core/models.dart';
import 'package:zakerly/core/util.dart';
import 'package:zakerly/ui/primitives/primitives.dart';

class StudyPanel extends StatefulWidget {
  const StudyPanel({super.key, required this.onVisualize, this.onOpenStatus});

  final void Function(Course course, String concept) onVisualize;
  final VoidCallback? onOpenStatus;

  @override
  State<StudyPanel> createState() => _StudyPanelState();
}

class _StudyPanelState extends State<StudyPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode();

  AppServices? _services;
  Listenable? _merged;

  String? _lastCourseId;
  int _lastThreadLength = 0;
  bool _lastPending = false;

  /// Thread messages at/after this index were added after this course was
  /// (re)mounted, so they get the entrance stagger; earlier ones render
  /// plain.
  int _animateFromIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = Services.of(context);
    if (!identical(_services, s)) {
      _merged?.removeListener(_handleCoreChange);
      _services = s;
      _merged = Listenable.merge([s.courses, s.session, s.tutor]);
      _merged!.addListener(_handleCoreChange);
      _handleCoreChange();
    }
  }

  @override
  void dispose() {
    _merged?.removeListener(_handleCoreChange);
    _controller.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Reacts to courses/session/tutor changes: picks a fallback course,
  /// tracks course switches (jump to bottom) and new-message scrolling.
  /// All side effects (state selection, scrolling) are scheduled for after
  /// the frame — never performed during build.
  void _handleCoreChange() {
    final s = _services;
    if (s == null) return;

    final courses = s.courses.courses;
    final courseId = s.session.courseId;
    final exists = courses.any((c) => c.id == courseId);

    if (courses.isNotEmpty && (courseId == null || !exists)) {
      final target = courses.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        s.session.selectCourse(target);
      });
      if (mounted) setState(() {});
      return;
    }

    final course = courseId == null ? null : s.courses.byId(courseId);
    if (course != null) {
      final thread = s.tutor.thread(course.id);
      final courseChanged = course.id != _lastCourseId;

      if (courseChanged) {
        _lastCourseId = course.id;
        _animateFromIndex = thread.length;
        _lastThreadLength = thread.length;
        _lastPending = thread.isNotEmpty && thread.last.pending;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scroll.hasClients) return;
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        });
      } else {
        final atBottom = !_scroll.hasClients || _scroll.position.extentAfter < ZSpace.s32;

        var studentSent = false;
        if (thread.length > _lastThreadLength) {
          for (var i = _lastThreadLength; i < thread.length; i++) {
            if (thread[i].author == Author.student) {
              studentSent = true;
              break;
            }
          }
        }
        final pendingNow = thread.isNotEmpty && thread.last.pending;
        final pendingFlipped = _lastPending && !pendingNow;

        _lastThreadLength = thread.length;
        _lastPending = pendingNow;

        if (atBottom || studentSent || pendingFlipped) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scroll.hasClients) return;
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: ZMotion.medium,
              curve: ZMotion.standard,
            );
          });
        }
      }
    }

    if (mounted) setState(() {});
  }

  void _send(AppServices s, Course course) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final included = s.session.includedFileIds(course);
    s.tutor.ask(course, included, text, s.session.mode);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _fillComposer(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final courses = s.courses.courses;
    final course = s.courses.byId(s.session.courseId) ?? (courses.isEmpty ? null : courses.first);

    return Padding(
      padding: const EdgeInsets.all(ZSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (course != null) ...[
            _buildHeader(context, s, course),
            const SizedBox(height: ZSpace.s16),
          ],
          Expanded(child: _buildBody(context, s, course, courses)),
          if (course != null && course.readyCount > 0) ...[
            const SizedBox(height: ZSpace.s12),
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _buildComposer(context, s, course),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Header ----------------------------------------------------------

  Widget _buildHeader(BuildContext context, AppServices s, Course course) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < ZLayout.compactBreakpoint;
        final segmented = ZSegmented<StudyMode>(
          segments: [for (final m in StudyMode.values) (m, m.label)],
          selected: s.session.mode,
          onChanged: s.session.setMode,
        );
        final pill = widget.onOpenStatus == null ? null : _buildBudgetPill(context, s);

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildHeaderTitle(context, course)),
                  if (pill != null) ...[const SizedBox(width: ZSpace.s12), pill],
                ],
              ),
              const SizedBox(height: ZSpace.s8),
              segmented,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildHeaderTitle(context, course)),
            const SizedBox(width: ZSpace.s12),
            SizedBox(width: ZLayout.segmentedWidth, child: segmented),
            if (pill != null) ...[const SizedBox(width: ZSpace.s12), pill],
          ],
        );
      },
    );
  }

  Widget _buildHeaderTitle(BuildContext context, Course course) {
    final z = context.z;
    return Row(
      children: [
        ZBadge(label: course.code),
        const SizedBox(width: ZSpace.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                course.name,
                style: context.type.titleMedium?.copyWith(color: z.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                course.term,
                style: context.type.bodySmall?.copyWith(color: z.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetPill(BuildContext context, AppServices s) {
    return ListenableBuilder(
      listenable: s.budget,
      builder: (context, _) {
        final z = context.z;
        return Semantics(
          button: true,
          label: 'Budget: ${formatTokens(s.budget.remaining)} tokens left. Open status',
          child: Pressable(
            onTap: widget.onOpenStatus,
            child: Glass(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZSpace.s12,
                  vertical: ZSpace.s8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ZRing(
                      fraction: s.budget.fraction,
                      size: ZLayout.pillRingSize,
                      stroke: ZLayout.pillRingStroke,
                    ),
                    const SizedBox(width: ZSpace.s8),
                    Text(
                      '${formatTokens(s.budget.remaining)} left',
                      style: context.type.labelLarge?.copyWith(color: z.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- Body --------------------------------------------------------------

  Widget _buildBody(
    BuildContext context,
    AppServices s,
    Course? course,
    List<Course> courses,
  ) {
    if (courses.isEmpty) {
      return const ZEmpty(
        icon: Icons.school_outlined,
        title: 'Sync your courses to start',
        message: 'Hit Sync on the left — we\'ll pull in your slides and readings.',
      );
    }

    final effCourse = course!;
    if (effCourse.readyCount == 0) {
      return _buildIndexEmpty(context, s, effCourse);
    }

    return _buildChat(context, s, effCourse);
  }

  Widget _buildIndexEmpty(BuildContext context, AppServices s, Course course) {
    Widget? action;
    String? message;

    if (!course.hasStarted && s.ingestion.canIndex(course)) {
      action = ZButton(
        label: 'Index now',
        onPressed: () => s.ingestion.indexCourse(course),
      );
    }
    if (course.hasPendingWork) {
      message = 'Big files finish overnight to save your budget. Check Status for progress.';
    }

    return ZEmpty(
      icon: Icons.library_books_outlined,
      title: 'Index ${course.code} to start',
      message: message,
      action: action,
    );
  }

  Widget _buildChat(BuildContext context, AppServices s, Course course) {
    final thread = s.tutor.thread(course.id);
    if (thread.isEmpty) {
      return _buildEmptyThread(context, course);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bubbleMax = math.min(
          ZLayout.bubbleMaxWidth,
          constraints.maxWidth * ZLayout.bubbleMaxFraction,
        );
        return ListView.builder(
          key: ValueKey(course.id),
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: ZSpace.s16),
          itemCount: thread.length,
          itemBuilder: (context, i) {
            final msg = thread[i];
            final priorStudentText =
                (msg.author == Author.tutor && i > 0 && thread[i - 1].author == Author.student)
                    ? thread[i - 1].text
                    : null;
            final isLastFinishedTutor = i == thread.length - 1 &&
                msg.author == Author.tutor &&
                !msg.pending &&
                !msg.failed;

            Widget bubble = _buildBubble(context, s, course, msg, priorStudentText);
            if (isLastFinishedTutor) {
              bubble = Semantics(liveRegion: true, child: bubble);
            }

            final aligned = Align(
              alignment:
                  msg.author == Author.student ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: bubbleMax),
                child: bubble,
              ),
            );

            final content = i < _animateFromIndex
                ? aligned
                : FadeSlideIn(index: i - _animateFromIndex, child: aligned);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: ZSpace.s4),
              child: content,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyThread(BuildContext context, Course course) {
    const suggestions = [
      'Summarize the key ideas',
      'Quiz me on this week',
      'Explain the hardest concept',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ZSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask anything about ${course.code}. Answers come only from your course files.',
              textAlign: TextAlign.center,
              style: context.type.titleMedium?.copyWith(color: context.z.text),
            ),
            const SizedBox(height: ZSpace.s16),
            Wrap(
              spacing: ZSpace.s8,
              runSpacing: ZSpace.s8,
              alignment: WrapAlignment.center,
              children: [
                for (final sugg in suggestions)
                  ZButton(
                    label: sugg,
                    variant: ZButtonVariant.tonal,
                    size: ZButtonSize.sm,
                    onPressed: () => _fillComposer(sugg),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    AppServices s,
    Course course,
    ChatMessage msg,
    String? priorStudentText,
  ) {
    final z = context.z;
    if (msg.author == Author.student) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ZSpace.s16,
          vertical: ZSpace.s12,
        ),
        decoration: BoxDecoration(
          color: z.accent,
          borderRadius: BorderRadius.circular(ZRadius.lg),
        ),
        child: Text(
          msg.text,
          style: context.type.bodyLarge?.copyWith(color: z.onAccent),
        ),
      );
    }

    final finished = !msg.pending && !msg.failed;
    return ZCard(
      padding: ZSpace.s12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (msg.pending)
            const ZTypingDots()
          else if (msg.failed)
            Text(
              msg.text,
              style: context.type.bodyLarge?.copyWith(color: z.danger),
            )
          else
            SelectableText(
              msg.text,
              style: context.type.bodyLarge?.copyWith(color: z.text),
            ),
          if (finished && msg.citations.isNotEmpty) ...[
            const SizedBox(height: ZSpace.s8),
            Wrap(
              spacing: ZSpace.s4,
              runSpacing: ZSpace.s4,
              children: [
                for (final c in msg.citations)
                  Semantics(
                    label: 'Source: ${c.fileName}, section ${c.heading}',
                    child: ExcludeSemantics(
                      child: ZBadge(
                        icon: Icons.description_outlined,
                        label: '${_stripExtension(c.fileName)} · ${c.heading}',
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (finished && msg.naiveTokens > 0) ...[
            const SizedBox(height: ZSpace.s8),
            _buildMetaCaption(context, msg),
          ],
          if (finished && priorStudentText != null) ...[
            const SizedBox(height: ZSpace.s4),
            ZButton(
              variant: ZButtonVariant.plain,
              size: ZButtonSize.sm,
              leading: Icons.auto_awesome_motion,
              label: 'Visualize',
              onPressed: s.budget.canGenerateAnimation
                  ? () => widget.onVisualize(course, priorStudentText)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaCaption(BuildContext context, ChatMessage msg) {
    final z = context.z;
    final saved = msg.naiveTokens > 0
        ? (((msg.naiveTokens - msg.tokens) / msg.naiveTokens) * 100).clamp(0, 100).round()
        : 0;
    return Text.rich(
      TextSpan(
        style: context.type.bodySmall?.copyWith(color: z.textSecondary),
        children: [
          TextSpan(
            text: '${formatTokens(msg.tokens)} tokens · '
                'full files: ${formatTokens(msg.naiveTokens)} · ',
          ),
          TextSpan(
            text: '$saved% saved',
            style: TextStyle(color: z.successText),
          ),
        ],
      ),
    );
  }

  // ---- Composer ------------------------------------------------------------

  Widget _buildComposer(BuildContext context, AppServices s, Course course) {
    final z = context.z;
    final thread = s.tutor.thread(course.id);
    final lastPending = thread.isNotEmpty && thread.last.pending;
    final included = s.session.includedFileIds(course);
    final text = _controller.text;
    final canSend = included.isNotEmpty && text.trim().isNotEmpty && !lastPending;

    String caption;
    Color captionColor = z.textSecondary;
    if (text.trim().isEmpty) {
      caption = 'Using ${included.length} files. Change them in Status.';
    } else {
      final plan = s.tutor.plan(course, included, text, s.session.mode);
      if (plan.chunks.isEmpty) {
        caption = 'Nothing in your files matches that — you won\'t spend any tokens.';
        captionColor = z.warning;
      } else {
        caption = '~${formatTokens(plan.promptTokens)} tokens from ${plan.chunks.length} sections '
            '· full files would be ${formatTokens(plan.naiveTokens)}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ZTextField(
                controller: _controller,
                focusNode: _focusNode,
                label: 'Ask the tutor',
                hint: 'Ask about ${course.code}…',
                enabled: included.isNotEmpty,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (canSend) _send(s, course);
                },
              ),
            ),
            const SizedBox(width: ZSpace.s8),
            ZIconButton(
              icon: Icons.arrow_upward,
              tooltip: 'Send',
              onPressed: canSend ? () => _send(s, course) : null,
            ),
          ],
        ),
        const SizedBox(height: ZSpace.s4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ZSpace.s4),
          child: Text(
            caption,
            style: context.type.bodySmall?.copyWith(color: captionColor),
          ),
        ),
      ],
    );
  }
}

String _stripExtension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot <= 0 ? fileName : fileName.substring(0, dot);
}
