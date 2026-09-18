// Center column of the one-screen workspace: course header, chat thread and
// composer. The message list is the only scrolling area in the app. The
// tutor thread is the hero of this panel and stays visible whenever a
// course is selected, whether or not any files have finished processing.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:zakerly/core/app_services.dart';
import 'package:zakerly/core/models.dart';
import 'package:zakerly/core/scheduler.dart';
import 'package:zakerly/core/util.dart';
import 'package:zakerly/ui/features/tutorial/tutorial_targets.dart';
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
  /// tracks course switches (jump to bottom), kicks off processing for a
  /// freshly-opened course, and new-message scrolling. All side effects
  /// (state selection, scrolling, processing) are scheduled for after the
  /// frame — never performed during build.
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

        if (!course.hasStarted && s.ingestion.canIndex(course)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            s.ingestion.indexCourse(course);
          });
        }

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

  /// Open jobs from the scheduler that belong to one of [course]'s
  /// not-yet-ready files, so "Process now" can bump exactly those.
  List<Job> _pendingJobsFor(AppServices s, Course course) {
    final pendingNames = {
      for (final f in course.files)
        if (f.status != FileStatus.ready) f.name,
    };
    return [
      for (final job in s.scheduler.open)
        if (job.label.startsWith('Process ') &&
            pendingNames.contains(job.label.substring('Process '.length)))
          job,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final courses = s.courses.courses;
    final course = s.courses.byId(s.session.courseId) ?? (courses.isEmpty ? null : courses.first);
    final note = course == null ? null : _buildProcessingNote(context, s, course);

    return Padding(
      padding: const EdgeInsets.all(ZLayout.panelPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (course != null) ...[
            _buildHeader(context, s, course),
            const SizedBox(height: ZLayout.sectionGap),
          ],
          Expanded(child: _buildBody(context, s, course, courses)),
          if (course != null) ...[
            const SizedBox(height: ZLayout.sectionGap),
            if (note != null) ...[
              note,
              const SizedBox(height: ZLayout.cardGap),
            ],
            ListenableBuilder(
              listenable: Listenable.merge([_controller, s.budget]),
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
          key: TutorialTargets.modes,
          segments: [for (final m in StudyMode.values) (m, m.label)],
          tooltips: [for (final m in StudyMode.values) m.tooltip],
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
          label: 'Budget: ${formatTokens(s.budget.remaining)} tokens left. Open Status',
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

  // ---- Processing note ----------------------------------------------------

  Widget? _buildProcessingNote(BuildContext context, AppServices s, Course course) {
    if (course.hasPendingWork) {
      final jobs = _pendingJobsFor(s, course);
      return _buildNote(
        context,
        text: 'Getting ${course.code} ready. You can ask about the files that are done.',
        action: jobs.isEmpty
            ? null
            : ZButton(
                label: 'Process now',
                variant: ZButtonVariant.tonal,
                size: ZButtonSize.sm,
                onPressed: () {
                  for (final job in jobs) {
                    s.scheduler.prioritize(job);
                  }
                },
              ),
      );
    }
    if (!course.hasStarted && !s.ingestion.canIndex(course)) {
      return _buildNote(
        context,
        text: 'The ${s.budget.plan.name} plan covers ${s.budget.plan.maxCourses} courses. '
            'Switch to Pro in Settings to open this one.',
      );
    }
    return null;
  }

  Widget _buildNote(BuildContext context, {required String text, Widget? action}) {
    final z = context.z;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ZSpace.s16, vertical: ZSpace.s12),
      decoration: BoxDecoration(
        color: z.raised2,
        borderRadius: BorderRadius.circular(ZRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom, size: ZIcon.md, color: z.textSecondary),
          const SizedBox(width: ZSpace.s12),
          Expanded(
            child: Text(text, style: context.type.bodySmall?.copyWith(color: z.textSecondary)),
          ),
          if (action != null) ...[const SizedBox(width: ZSpace.s12), action],
        ],
      ),
    );
  }

  // ---- Body --------------------------------------------------------------

  Widget _buildBody(
    BuildContext context,
    AppServices s,
    Course? course,
    List<Course> courses,
  ) {
    if (courses.isEmpty || course == null) {
      return const ZEmpty(
        icon: Icons.school_outlined,
        title: 'Sync your courses to start',
        message: 'Tap Sync next to Canvas and I\'ll bring in your slides and readings.',
      );
    }

    return _buildChat(context, s, course);
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
            final isLastFinishedTutor = i == thread.length - 1 &&
                msg.author == Author.tutor &&
                !msg.pending &&
                !msg.failed;

            Widget bubble = _buildBubble(context, msg);
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
    final z = context.z;
    const suggestions = [
      'Sum up the main ideas',
      'Quiz me on this week',
      'Explain the hardest part',
    ];
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ZLayout.bubbleMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ZSpace.s16),
          child: FadeSlideIn(
            index: 0,
            child: ZCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hi! Ask me anything about ${course.code}. '
                    'I\'ll answer from your course files.',
                    style: context.type.bodyLarge?.copyWith(color: z.text),
                  ),
                  const SizedBox(height: ZSpace.s16),
                  Wrap(
                    spacing: ZSpace.s8,
                    runSpacing: ZSpace.s8,
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
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, ChatMessage msg) {
    final z = context.z;
    if (msg.author == Author.student) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ZSpace.s16,
          vertical: ZSpace.s16,
        ),
        decoration: BoxDecoration(
          color: z.accent,
          borderRadius: BorderRadius.circular(ZRadius.card),
        ),
        child: Text(
          msg.text,
          style: context.type.bodyLarge?.copyWith(color: z.onAccent),
        ),
      );
    }

    final finished = !msg.pending && !msg.failed;
    return ZCard(
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
            const SizedBox(height: ZSpace.s12),
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
            const SizedBox(height: ZSpace.s12),
            _buildMetaCaption(context, msg),
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
          TextSpan(text: '${formatTokens(msg.tokens)} tokens · '),
          TextSpan(
            text: '$saved% less than sending the full files',
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
    final canSend = text.trim().isNotEmpty && !lastPending;

    String? lastConcept;
    for (var i = thread.length - 1; i >= 0; i--) {
      final m = thread[i];
      if (m.author == Author.tutor && !m.pending && !m.failed) {
        if (i > 0 && thread[i - 1].author == Author.student) {
          lastConcept = thread[i - 1].text;
        }
        break;
      }
    }
    final canVisualize = lastConcept != null && s.budget.canGenerateAnimation;

    String caption;
    Color captionColor = z.textSecondary;
    if (text.trim().isEmpty) {
      caption = included.isEmpty
          ? 'Your files aren\'t ready yet. You can still ask.'
          : 'Using ${_count(included.length, 'file')}. Change them in Status.';
    } else {
      final plan = s.tutor.plan(course, included, text, s.session.mode);
      if (plan.chunks.isEmpty) {
        caption = 'Nothing in your files matches that, so this one is free.';
        captionColor = z.warning;
      } else {
        caption = 'About ${formatTokens(plan.promptTokens)} tokens from '
            '${_count(plan.chunks.length, 'section')}. '
            'The full files would cost ${formatTokens(plan.naiveTokens)}.';
      }
    }

    return Column(
      key: TutorialTargets.composer,
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
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (canSend) _send(s, course);
                },
              ),
            ),
            const SizedBox(width: ZSpace.s8),
            ZIconButton(
              key: TutorialTargets.visualize,
              icon: Icons.auto_awesome_motion,
              tooltip: 'Animate the last answer',
              onPressed: canVisualize ? () => widget.onVisualize(course, lastConcept!) : null,
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

/// "1 file", "3 files".
String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

String _stripExtension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot <= 0 ? fileName : fileName.substring(0, dot);
}
