import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/budget.dart';
import '../../../core/models.dart';
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
  const CourseRail({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

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
    _confirmTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _justSynced = false);
    });
  }

  Future<void> _handleSync(AppServices s) => syncAndStartCourses(s);

  void _selectCourse(AppServices s, Course course) {
    s.session.selectCourse(course.id);
    if (!course.hasStarted && s.ingestion.canIndex(course)) {
      s.ingestion.indexCourse(course);
    }
  }

  /// "5:01 pm", matching how the scheduler writes times.
  String _formatTime(DateTime dt) {
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h12:$m ${dt.hour < 12 ? 'am' : 'pm'}';
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final z = context.z;
    return Container(
      decoration: BoxDecoration(
        color: z.raised,
        border: Border(right: BorderSide(color: z.hairline)),
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
      padding: EdgeInsets.fromLTRB(ZSpace.s20, ZSpace.s20, ZSpace.s20, ZSpace.s12),
      child: ZLogo(size: 28, withWordmark: true),
    );
  }

  Widget _buildCanvasSection(BuildContext context, AppServices s) {
    final z = context.z;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ZSpace.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ZEyebrow('Canvas'),
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
                              'Synced',
                              style: context.type.bodySmall?.copyWith(color: z.successText),
                            ),
                          ],
                        )
                      : Tooltip(
                          key: const ValueKey('caption'),
                          message: s.lms.host,
                          child: Text(
                            s.courses.lastSynced != null
                                ? 'Synced ${_formatTime(s.courses.lastSynced!)}'
                                : 'Not synced yet',
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
                label: 'Sync',
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
              message: s.courses.error!,
              child: Text(
                s.courses.error!,
                style: context.type.bodySmall?.copyWith(color: z.danger),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
    if (courses.isEmpty) {
      return const ZEmpty(
        icon: Icons.cloud_sync_outlined,
        title: 'No courses yet',
        message: 'Tap Sync above to bring them in from Canvas.',
      );
    }

    final selectedId = s.session.courseId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ZSpace.s20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const tileExtent = 76.0;
          const moreRowExtent = 24.0;
          final maxTiles =
              ((constraints.maxHeight - moreRowExtent) / tileExtent).floor().clamp(1, 6).toInt();
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
                  '+$remaining more',
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
    final user = s.auth.user.value;
    final initial = (user != null && user.name.isNotEmpty) ? user.name[0].toUpperCase() : '?';
    final isPro = s.budget.tier != PlanTier.free;
    return Padding(
      padding: const EdgeInsets.fromLTRB(ZSpace.s20, ZSpace.s12, ZSpace.s20, ZSpace.s16),
      child: Row(
        children: [
          Container(
            width: ZSpace.s24 + ZSpace.s4,
            height: ZSpace.s24 + ZSpace.s4,
            decoration: BoxDecoration(color: z.accentSoft, shape: BoxShape.circle),
            child: Center(
              child: Text(initial, style: context.type.labelLarge?.copyWith(color: z.accent)),
            ),
          ),
          const SizedBox(width: ZSpace.s8),
          Expanded(
            child: Text(
              user?.name ?? 'Guest',
              style: context.type.bodyMedium?.copyWith(color: z.text),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: ZSpace.s8),
          ZBadge(
            label: s.budget.plan.name,
            tone: isPro ? ZBadgeTone.accent : ZBadgeTone.neutral,
          ),
          const SizedBox(width: ZSpace.s4),
          ZIconButton(
            key: TutorialTargets.settings,
            icon: Icons.tune,
            tooltip: 'Settings',
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
      statusText = 'Getting ready…';
    } else if (course.isFullyIndexed) {
      statusText = 'Ready';
    } else if (!course.hasStarted && canIndex) {
      statusText = 'Not started';
    } else if (!course.hasStarted) {
      statusText = 'Needs Pro';
      trailing = Tooltip(
        message: 'The ${s.budget.plan.name} plan covers ${s.budget.plan.maxCourses} courses',
        child: Icon(Icons.lock_outline, size: ZIcon.sm, color: z.textTertiary),
      );
    } else if (failed > 0) {
      statusText = '$failed didn\'t load';
      statusColor = z.danger;
    } else {
      statusText = '$readyCount/$total ready';
    }

    final lockedSuffix = (!course.hasStarted && !canIndex)
        ? '. The ${s.budget.plan.name} plan covers ${s.budget.plan.maxCourses} courses'
        : '';
    final semanticsLabel =
        '${course.name}, ${course.code}, $statusText$lockedSuffix${selected ? ', selected' : ''}';

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
                      size: 7,
                      child: ZRing(
                        fraction: fraction,
                        size: 24,
                        stroke: 3,
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
