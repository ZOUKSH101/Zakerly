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
import 'package:zakerly/l10n/strings.dart';
import 'package:zakerly/ui/features/tutorial/tutorial_targets.dart';
import 'package:zakerly/ui/primitives/primitives.dart';

import 'citations.dart';

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
    _ask(s, course, text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _ask(AppServices s, Course course, String question) {
    final included = s.session.includedFileIds(course);
    s.tutor.ask(course, included, question, s.session.mode);
  }

  /// The question the latest finished answer replied to, which is what an
  /// animation of "the last answer" should draw.
  String? _lastConcept(List<ChatMessage> thread) {
    for (var i = thread.length - 1; i >= 0; i--) {
      final m = thread[i];
      if (m.author == Author.tutor && !m.pending && !m.failed) {
        if (i > 0 && thread[i - 1].author == Author.student) return thread[i - 1].text;
        return null;
      }
    }
    return null;
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
        if (pendingNames.contains(_processSubject(job))) job,
    ];
  }

  /// The file a "process" job works on, or null for any other job.
  static String? _processSubject(Job job) {
    if (job.kind == JobKind.process) return job.subject;
    const prefix = 'Process ';
    return job.label.startsWith(prefix) ? job.label.substring(prefix.length) : null;
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
        final t = S.of(context);
        final segmented = ZSegmented<StudyMode>(
          key: TutorialTargets.modes,
          segments: [for (final m in StudyMode.values) (m, t.modeLabel(m))],
          tooltips: [for (final m in StudyMode.values) t.modeTooltip(m)],
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
        final t = S.of(context);
        return Semantics(
          button: true,
          label: t.budgetPillSemantics(formatTokens(s.budget.remaining)),
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
                      t.tokensLeft(formatTokens(s.budget.remaining)),
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
    final t = S.of(context);
    if (course.hasPendingWork) {
      final jobs = _pendingJobsFor(s, course);
      return _buildNote(
        context,
        text: t.gettingCourseReady(course.code),
        action: jobs.isEmpty
            ? null
            : ZButton(
                label: t.processNow,
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
        text: t.planLimitNote(t.planName(s.budget.tier), s.budget.plan.maxCourses),
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
      final t = S.of(context);
      return ZEmpty(
        icon: Icons.school_outlined,
        title: t.syncToStartTitle,
        message: t.syncToStartBody,
      );
    }

    return _buildChat(context, s, course);
  }

  Widget _buildChat(BuildContext context, AppServices s, Course course) {
    final thread = s.tutor.thread(course.id);
    if (thread.isEmpty) {
      return _buildEmptyThread(context, s, course);
    }
    final lastConcept = _lastConcept(thread);

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

            final showAnimate =
                isLastFinishedTutor && lastConcept != null && msg.citations.isNotEmpty;
            Widget bubble = _buildBubble(
              context,
              msg,
              showAnimate: showAnimate,
              onAnimate: showAnimate && s.budget.canGenerateAnimation
                  ? () => widget.onVisualize(course, lastConcept)
                  : null,
            );
            if (isLastFinishedTutor) {
              bubble = Semantics(liveRegion: true, child: bubble);
            }

            final aligned = Align(
              alignment: msg.author == Author.student
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
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

  /// An empty thread is a home screen: one large question, the course it's
  /// about, and three starters that send on tap.
  Widget _buildEmptyThread(BuildContext context, AppServices s, Course course) {
    final z = context.z;
    final t = S.of(context);
    final starters = [
      (Icons.notes_rounded, t.starterSummary),
      (Icons.quiz_outlined, t.starterQuiz),
      (Icons.lightbulb_outline_rounded, t.starterHardest),
    ];
    final ready = course.files.isNotEmpty && course.isFullyIndexed;
    final subline = ready ? t.homeReady(course.name) : t.homeNotReady(course.name);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Short viewports: keep the block reachable rather than clipped.
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ZLayout.homeMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: ZSpace.s24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeSlideIn(
                        index: 0,
                        offset: ZMotion.staggerSectionTravel,
                        child: Column(
                          children: [
                            Text(
                              t.homeTitle,
                              textAlign: TextAlign.center,
                              style: context.type.displaySmall?.copyWith(color: z.text),
                            ),
                            const SizedBox(height: ZSpace.s12),
                            Text(
                              subline,
                              textAlign: TextAlign.center,
                              style: context.type.bodyLarge?.copyWith(color: z.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ZSpace.s32),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: ZSpace.s8,
                        runSpacing: ZSpace.s8,
                        children: [
                          for (final (i, (icon, label)) in starters.indexed)
                            FadeSlideIn(
                              index: i + 1,
                              child: ZChip(
                                icon: icon,
                                label: label,
                                onPressed: () => _ask(s, course, label),
                              ),
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
      },
    );
  }

  Widget _buildBubble(
    BuildContext context,
    ChatMessage msg, {
    bool showAnimate = false,
    VoidCallback? onAnimate,
  }) {
    final z = context.z;
    final t = S.of(context);
    if (msg.author == Author.student) {
      // Brand bubble shape: lg corners, the one nearest the speaker at sm.
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ZSpace.s16,
          vertical: ZSpace.s12,
        ),
        decoration: BoxDecoration(
          color: z.accent,
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(ZRadius.lg),
            topEnd: Radius.circular(ZRadius.lg),
            bottomStart: Radius.circular(ZRadius.lg),
            bottomEnd: Radius.circular(ZRadius.sm),
          ).resolve(Directionality.of(context)),
        ),
        child: Text(
          msg.text,
          style: context.type.bodyLarge?.copyWith(color: z.onAccent),
        ),
      );
    }

    final finished = !msg.pending && !msg.failed;
    if (!finished) {
      return ZCard(
        padding: ZSpace.s20,
        child: msg.pending
            ? const ZTypingDots()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.error_outline_rounded, size: ZIcon.md, color: z.danger),
                  ),
                  const SizedBox(width: ZSpace.s8),
                  Expanded(
                    child: Text(
                      msg.notice == null ? msg.text : t.tutorNotice(msg.notice!),
                      style: context.type.bodyLarge?.copyWith(color: z.text),
                    ),
                  ),
                ],
              ),
      );
    }

    final parsed = parseAnswer(
      msg.notice == null ? msg.text : t.tutorNotice(msg.notice!),
      fallback: msg.citations,
    );
    final body = context.type.bodyLarge?.copyWith(color: z.text);
    return ZCard(
      padding: ZSpace.s20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectionArea(
            child: Text.rich(
              TextSpan(
                style: body,
                children: [
                  for (final part in parsed.parts)
                    switch (part) {
                      AnswerText(:final text) => TextSpan(text: text),
                      AnswerCite(:final number) => WidgetSpan(
                          alignment: PlaceholderAlignment.top,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 3, end: 1),
                            child: _CiteMark(
                              number: number,
                              source: parsed.sources[number - 1],
                            ),
                          ),
                        ),
                    },
                ],
              ),
            ),
          ),
          if (parsed.sources.isNotEmpty) ...[
            const SizedBox(height: ZSpace.s16),
            Container(height: 1, color: z.hairline),
            const SizedBox(height: ZSpace.s12),
            for (final (i, source) in parsed.sources.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : ZSpace.s8),
                child: _SourceRow(number: i + 1, source: source),
              ),
          ],
          if (showAnimate || msg.naiveTokens > 0) ...[
            const SizedBox(height: ZSpace.s16),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: ZSpace.s12,
              runSpacing: ZSpace.s8,
              children: [
                if (showAnimate)
                  Tooltip(
                    message: onAnimate == null ? t.animateLimitTooltip : t.animateTooltip,
                    child: ZButton(
                      key: const ValueKey('animate-answer'),
                      label: t.animateIt,
                      leading: Icons.play_circle_outline_rounded,
                      variant: ZButtonVariant.tonal,
                      size: ZButtonSize.sm,
                      onPressed: onAnimate,
                    ),
                  ),
                if (msg.naiveTokens > 0) _buildMetaCaption(context, msg),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaCaption(BuildContext context, ChatMessage msg) {
    final z = context.z;
    final t = S.of(context);
    final saved = msg.naiveTokens > 0
        ? (((msg.naiveTokens - msg.tokens) / msg.naiveTokens) * 100).clamp(0, 100).round()
        : 0;
    return Text.rich(
      TextSpan(
        style: context.type.bodySmall?.copyWith(color: z.textSecondary),
        children: [
          TextSpan(text: t.metaTokens(formatTokens(msg.tokens))),
          TextSpan(
            text: t.metaSaved(saved),
            style: TextStyle(color: z.successText),
          ),
        ],
      ),
    );
  }

  // ---- Composer ------------------------------------------------------------

  Widget _buildComposer(BuildContext context, AppServices s, Course course) {
    final z = context.z;
    final t = S.of(context);
    final thread = s.tutor.thread(course.id);
    final lastPending = thread.isNotEmpty && thread.last.pending;
    final included = s.session.includedFileIds(course);
    final text = _controller.text;
    final canSend = text.trim().isNotEmpty && !lastPending;

    final lastConcept = _lastConcept(thread);
    final canVisualize = lastConcept != null && s.budget.canGenerateAnimation;

    String caption;
    Color captionColor = z.textSecondary;
    if (text.trim().isEmpty) {
      caption = included.isEmpty
          ? t.composerFilesNotReady
          : t.composerUsingFiles(included.length);
    } else {
      final plan = s.tutor.plan(course, included, text, s.session.mode);
      if (plan.chunks.isEmpty) {
        caption = t.composerNoMatch;
        captionColor = z.warning;
      } else {
        caption = t.composerEstimate(
          formatTokens(plan.promptTokens),
          plan.chunks.length,
          formatTokens(plan.naiveTokens),
        );
      }
    }

    return Column(
      key: TutorialTargets.composer,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ZComposer(
          controller: _controller,
          focusNode: _focusNode,
          semanticLabel: t.askTheTutor,
          hint: t.askAbout(course.code),
          sendTooltip: t.send,
          canSend: canSend,
          onSend: () => _send(s, course),
          actions: [
            ZIconButton(
              key: TutorialTargets.visualize,
              icon: Icons.play_circle_outline_rounded,
              tooltip: t.animateLastAnswer,
              onPressed: canVisualize ? () => widget.onVisualize(course, lastConcept) : null,
            ),
          ],
        ),
        const SizedBox(height: ZSpace.s8),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: ZSpace.s20, end: ZSpace.s20),
          child: Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type.bodySmall?.copyWith(color: captionColor),
          ),
        ),
      ],
    );
  }
}

/// Small numbered superscript pill for an inline source. Hover shows the
/// file and section; screen readers hear "source 1".
class _CiteMark extends StatelessWidget {
  const _CiteMark({required this.number, required this.source});

  final int number;
  final Citation source;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final style = context.type.labelSmall;
    return Tooltip(
      message: '${stripExtension(source.fileName)} · ${source.heading}',
      child: Semantics(
        label: S.of(context).sourceSemantics(number, source.fileName, source.heading),
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minWidth: 16),
          height: 16,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: z.accentSoft,
            borderRadius: BorderRadius.circular(ZRadius.pill),
          ),
          child: Text(
            '$number',
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
    );
  }
}

/// One line of the source list under an answer: the same numbered pill,
/// then the file and the section.
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.number, required this.source});

  final int number;
  final Citation source;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final caption = context.type.bodySmall;
    final file = stripExtension(source.fileName);
    return Row(
      children: [
        ExcludeSemantics(child: _CiteMark(number: number, source: source)),
        const SizedBox(width: ZSpace.s8),
        Expanded(
          child: Tooltip(
            message: '${source.fileName} · ${source.heading}',
            waitDuration: const Duration(milliseconds: 600),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: file,
                    style: caption == null
                        ? null
                        : ZType.withWeight(caption, FontWeight.w500).copyWith(color: z.text),
                  ),
                  TextSpan(
                    text: ' · ${source.heading}',
                    style: caption?.copyWith(color: z.textSecondary),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
