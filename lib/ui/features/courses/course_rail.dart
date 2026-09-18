import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/budget.dart';
import '../../../core/models.dart';
import '../../primitives/primitives.dart';

/// LEFT column of the one-screen workspace: brand header, Canvas sync
/// controls and the course list, with the signed-in user pinned at the
/// bottom. Meant to be placed by the integrator at 248-272px wide, full
/// viewport height. Never scrolls; the course list caps itself to whatever
/// fits the available height (at most 6 tiles).
class CourseRail extends StatelessWidget {
  const CourseRail({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  Future<void> _handleSync(AppServices s) async {
    await s.courses.sync();
    final courses = s.courses.courses;
    if (courses.isEmpty) return;
    final current = s.session.courseId;
    if (current == null || s.courses.byId(current) == null) {
      s.session.selectCourse(courses.first.id);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
            child: ListenableBuilder(
              listenable: Listenable.merge([s.courses, s.session, s.budget]),
              builder: (context, _) => _buildCourseList(context, s),
            ),
          ),
          const Divider(height: 1),
          ListenableBuilder(
            listenable: Listenable.merge([s.budget, s.auth.user]),
            builder: (context, _) => _buildFooter(context, s),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    final z = context.z;
    return Padding(
      padding: const EdgeInsets.fromLTRB(ZSpace.s16, ZSpace.s16, ZSpace.s16, ZSpace.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('Zakerly', style: context.type.titleLarge),
          const SizedBox(width: ZSpace.s8),
          Text(
            'ذاكرلي',
            style: context.type.bodySmall?.copyWith(color: z.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasSection(BuildContext context, AppServices s) {
    final z = context.z;
    final syncedCaption =
        s.courses.lastSynced != null ? 'Synced ${_formatTime(s.courses.lastSynced!)}' : 'Not synced yet';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ZSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ZEyebrow('CANVAS'),
          const SizedBox(height: ZSpace.s8),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.lms.host,
                  style: context.type.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: ZSpace.s8),
              ZButton(
                label: 'Sync',
                size: ZButtonSize.sm,
                variant: ZButtonVariant.tonal,
                leading: Icons.sync,
                loading: s.courses.syncing,
                onPressed: () => _handleSync(s),
              ),
            ],
          ),
          const SizedBox(height: ZSpace.s4),
          Text(
            syncedCaption,
            style: context.type.bodySmall?.copyWith(color: z.textSecondary),
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
          const SizedBox(height: ZSpace.s12),
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
        message: 'Tap Sync above to pull them in from Canvas.',
      );
    }

    final selectedId = s.session.courseId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ZSpace.s16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const tileExtent = 68.0;
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
      padding: const EdgeInsets.fromLTRB(ZSpace.s16, ZSpace.s12, ZSpace.s16, ZSpace.s12),
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
            icon: Icons.tune,
            tooltip: 'Settings',
            onPressed: onOpenSettings,
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
  });

  final Course course;
  final int index;
  final bool selected;
  final AppServices s;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final total = course.files.length;
    final ready = course.readyCount;
    final failed = course.files.where((f) => f.status == FileStatus.failed).length;
    final fraction = total == 0 ? 0.0 : ready / total;
    final canIndex = s.ingestion.canIndex(course);

    String statusText;
    Color? statusColor;
    Widget? trailing;

    if (course.hasPendingWork) {
      statusText = 'Indexing…';
      trailing = const ZSpinner(size: 16);
    } else if (course.isFullyIndexed) {
      statusText = 'Ready';
    } else if (!course.hasStarted && canIndex) {
      statusText = 'Not indexed';
      trailing = ZIconButton(
        icon: Icons.playlist_add,
        tooltip: 'Index ${course.name}',
        onPressed: () => s.ingestion.indexCourse(course),
      );
    } else if (!course.hasStarted) {
      statusText = 'Locked';
      trailing = const ZBadge(
        tone: ZBadgeTone.warning,
        icon: Icons.lock_outline,
        label: 'Locked · Pro',
      );
    } else if (failed > 0) {
      statusText = '$failed failed';
      statusColor = z.danger;
    } else {
      statusText = '$ready/$total indexed';
    }

    final lockedSuffix = (!course.hasStarted && !canIndex)
        ? '. Free plan covers ${s.budget.plan.maxCourses} courses.'
        : '';
    final semanticsLabel =
        '${course.name}, ${course.code}, $statusText$lockedSuffix${selected ? ', selected' : ''}';

    return FadeSlideIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: ZSpace.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                container: true,
                button: true,
                selected: selected,
                label: semanticsLabel,
                child: Pressable(
                  onTap: () => s.session.selectCourse(course.id),
                  child: ExcludeSemantics(
                    child: AnimatedContainer(
                      duration: ZMotion.medium,
                      curve: ZMotion.standard,
                      padding: const EdgeInsets.symmetric(
                        horizontal: ZSpace.s12,
                        vertical: ZSpace.s8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? z.accentSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(ZRadius.md),
                        border: Border.all(color: selected ? z.accent : Colors.transparent),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ZRing(fraction: fraction, size: 24, stroke: 3),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: ZSpace.s8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
