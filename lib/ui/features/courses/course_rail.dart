import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/budget.dart';
import '../../../core/models.dart';
import '../../../l10n/strings.dart';
import '../../primitives/primitives.dart';
import '../tutorial/tutorial_targets.dart';
import 'course_sync.dart';

/// LEFT column of the one-screen workspace: brand mark, Canvas sync
/// controls and the course list, with the signed-in user pinned at the
/// bottom. Meant to be placed by the integrator at 248-272px wide, full
/// viewport height. Never scrolls; the course list caps itself to whatever
/// fits the available height (at most 6 tiles).
///
/// Syncing shows a spinner on the Sync button, then a brief "Synced"
/// confirmation, then automatically starts getting ready whichever courses
/// the plan still allows. Picking an unstarted course does the same.
class CourseRail extends StatefulWidget {
  const CourseRail({super.key, required this.onOpenSettings, this.onCourseSelected});

  final VoidCallback onOpenSettings;

  /// Called after a course is picked (also when it was already selected).
  /// On phones the workspace uses it to switch to the chat tab.
  final VoidCallback? onCourseSelected;

  @override
  State<CourseRail> createState() => _CourseRailState();
}

class _CourseRailState extends State<CourseRail> {
  bool _justSynced = false;
  Timer? _confirmTimer;
  AppServices? _services;
  DateTime? _seenSync;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = Services.of(context);
    if (!identical(s, _services)) {
      _services?.courses.removeListener(_onCourses);
      _services = s;
      _seenSync = s.courses.lastSynced;
      s.courses.addListener(_onCourses);
    }
  }

  @override
  void dispose() {
    _services?.courses.removeListener(_onCourses);
    _confirmTimer?.cancel();
    super.dispose();
  }

  /// Shows the brief "Synced" check whenever a sync finishes, whether it
  /// came from the button or from the workspace's sign-in sync.
  void _onCourses() {
    final last = _services?.courses.lastSynced;
    if (last == null || last == _seenSync || !mounted) return;
    _seenSync = last;
    setState(() => _justSynced = true);
    _confirmTimer?.cancel();
    _confirmTimer = Timer(ZMotion.confirm, () {
      if (mounted) setState(() => _justSynced = false);
    });
  }

  Future<void> _handleSync(AppServices s) => syncAndStartCourses(s);

  void _selectCourse(AppServices s, Course course) {
    s.session.selectCourse(course.id);
    if (!course.hasStarted && s.ingestion.canIndex(course)) {
      s.ingestion.indexCourse(course);
    }
    widget.onCourseSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final z = context.z;
    return Container(
      decoration: BoxDecoration(
        color: z.raised,
        // The rail's inner edge: right in LTR, left once the row mirrors.
        border: BorderDirectional(end: BorderSide(color: z.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: s.courses,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBrandHeader(context),
                _buildCanvasSection(context, s),
              ],
            ),
          ),
          Expanded(
            key: TutorialTargets.courses,
            child: ListenableBuilder(
              listenable: Listenable.merge([s.courses, s.session, s.budget]),
              builder: (context, _) => _buildCourseList(context, s),
            ),
          ),
          Divider(height: 1, color: z.hairline),
          ListenableBuilder(
            listenable: Listenable.merge([s.budget, s.auth.user]),
            builder: (context, _) => _buildFooter(context, s),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        ZLayout.panelPadding,
        ZLayout.panelPadding,
        ZLayout.panelPadding,
        ZSpace.s12,
      ),
      child: ZLogo(size: ZLayout.railLogoSize, withWordmark: true),
    );
  }

  Widget _buildCanvasSection(BuildContext context, AppServices s) {
    final z = context.z;
    final t = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ZLayout.panelPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZEyebrow(t.canvas),
          const SizedBox(height: ZSpace.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: ZMotion.medium,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [...previous, ?current],
                  ),
                  child: _justSynced
                      ? Row(
                          key: const ValueKey('synced'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: ZIcon.sm, color: z.success),
                            const SizedBox(width: ZSpace.s4),
                            Text(
                              t.synced,
                              style: context.type.bodySmall?.copyWith(color: z.successText),
                            ),
                          ],
                        )
                      : Tooltip(
                          key: const ValueKey('caption'),
                          message: s.lms.host,
                          child: Text(
                            s.courses.lastSynced != null
                                ? t.syncedAt(t.clock(s.courses.lastSynced!))
                                : t.notSyncedYet,
                            style: context.type.bodySmall?.copyWith(color: z.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: ZSpace.s8),
              ZButton(
                key: TutorialTargets.sync,
                label: t.sync,
                size: ZButtonSize.sm,
                variant: ZButtonVariant.tonal,
                leading: Icons.sync,
                loading: s.courses.syncing,
                onPressed: () => _handleSync(s),
              ),
            ],
          ),
          if (s.courses.error != null) ...[
            const SizedBox(height: ZSpace.s4),
            Tooltip(
              message: t.syncFailed,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: ZLayout.nudge),
                    child: Icon(Icons.error_outline_rounded, size: ZIcon.sm, color: z.danger),
                  ),
                  const SizedBox(width: ZSpace.s4),
                  Expanded(
                    child: Text(
                      t.syncFailed,
                      style: context.type.bodySmall?.copyWith(color: z.danger),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: ZSpace.s16),
        ],
      ),
    );
  }

  Widget _buildCourseList(BuildContext context, AppServices s) {
    final courses = s.courses.courses;
    final t = S.of(context);
    if (courses.isEmpty) {
      return ZEmpty(
        icon: Icons.cloud_sync_outlined,
        title: t.noCoursesTitle,
        message: t.noCoursesBody,
      );
    }

    final selectedId = s.session.courseId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ZLayout.panelPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxTiles = ((constraints.maxHeight - ZLayout.moreRowExtent) /
                  ZLayout.courseTileExtent)
              .floor()
              .clamp(1, ZLayout.maxCourseTiles)
              .toInt();
          final shown = courses.take(maxTiles).toList();
          final remaining = courses.length - shown.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < shown.length; i++)
                _CourseTile(
                  key: ValueKey(shown[i].id),
                  course: shown[i],
                  index: i,
                  selected: shown[i].id == selectedId,
                  s: s,
                  onSelect: _selectCourse,
                ),
              if (remaining > 0)
                Text(
                  t.more(remaining),
                  style: context.type.bodySmall?.copyWith(color: context.z.textSecondary),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppServices s) {
    final z = context.z;
    final t = S.of(context);
    final user = s.auth.user.value;
    final isPro = s.budget.tier != PlanTier.free;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ZLayout.panelPadding,
        ZSpace.s12,
        ZLayout.panelPadding,
        ZSpace.s16,
      ),
      child: Row(
        children: [
          ZAvatar(name: user?.name ?? ''),
          const SizedBox(width: ZSpace.s8),
          Expanded(
            child: Text(
              user?.name ?? t.guest,
              style: context.type.bodyMedium?.copyWith(color: z.text),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: ZSpace.s8),
          ZBadge(
            label: t.planName(s.budget.tier),
            tone: isPro ? ZBadgeTone.accent : ZBadgeTone.neutral,
          ),
          const SizedBox(width: ZSpace.s4),
          ZIconButton(
            key: TutorialTargets.settings,
            icon: Icons.tune,
            tooltip: t.settings,
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    super.key,
    required this.course,
    required this.index,
    required this.selected,
    required this.s,
    required this.onSelect,
  });

  final Course course;
  final int index;
  final bool selected;
  final AppServices s;
  final void Function(AppServices s, Course course) onSelect;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final t = S.of(context);
    final planName = t.planName(s.budget.tier);
    final total = course.files.length;
    final readyCount = course.readyCount;
    final ready = total > 0 && course.isFullyIndexed;
    final failed = course.files.where((f) => f.status == FileStatus.failed).length;
    final fraction = total == 0 ? 0.0 : readyCount / total;
    final canIndex = s.ingestion.canIndex(course);

    String statusText;
    Color? statusColor;
    Widget? trailing;

    if (course.hasPendingWork) {
      // The ring already shows progress; no extra spinner to squeeze the name.
      statusText = t.courseGettingReady;
    } else if (course.isFullyIndexed) {
      statusText = t.courseReady;
    } else if (!course.hasStarted && canIndex) {
      statusText = t.courseNotStarted;
    } else if (!course.hasStarted) {
      statusText = t.needsPro;
      trailing = Tooltip(
        message: t.planCovers(planName, s.budget.plan.maxCourses),
        child: Icon(Icons.lock_outline, size: ZIcon.sm, color: z.textTertiary),
      );
    } else if (failed > 0) {
      statusText = t.filesFailed(failed);
      statusColor = z.danger;
    } else {
      statusText = t.readyOfTotal(readyCount, total);
    }

    final comma = t.isArabic ? '، ' : ', ';
    final lockedSuffix = (!course.hasStarted && !canIndex)
        ? '. ${t.planCovers(planName, s.budget.plan.maxCourses)}'
        : '';
    final semanticsLabel = '${course.name}$comma${course.code}$comma$statusText$lockedSuffix'
        '${selected ? t.selectedSuffix : ''}';

    return FadeSlideIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: ZSpace.s8),
        child: Semantics(
          container: true,
          button: true,
          selected: selected,
          label: semanticsLabel,
          child: Pressable(
            onTap: () => onSelect(s, course),
            child: ExcludeSemantics(
              child: AnimatedContainer(
                duration: ZMotion.medium,
                curve: ZMotion.standard,
                padding: const EdgeInsets.symmetric(
                  horizontal: ZSpace.s16,
                  vertical: ZSpace.s12,
                ),
                decoration: BoxDecoration(
                  color: selected ? z.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(ZRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Course ready (BRAND.md delight 2): the ring closes,
                    // turns Mint, and the amber spark hops off its top.
                    ZSpark(
                      fired: ready,
                      size: ZLayout.courseSparkSize,
                      child: ZRing(
                        fraction: fraction,
                        size: ZLayout.courseRingSize,
                        stroke: ZLayout.courseRingStroke,
                        color: ready ? z.success : z.accent,
                      ),
                    ),
                    const SizedBox(width: ZSpace.s12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: context.type.bodyLarge?.copyWith(color: z.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text.rich(
                            TextSpan(
                              style: context.type.bodySmall?.copyWith(color: z.textSecondary),
                              children: [
                                TextSpan(text: '${course.code} · '),
                                TextSpan(
                                  text: statusText,
                                  style: statusColor != null
                                      ? TextStyle(color: statusColor)
                                      : null,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: ZSpace.s8),
                      trailing,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
