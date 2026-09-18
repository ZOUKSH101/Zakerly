// StatusPanel: the right-hand column of the one-screen workspace. An Apple
// widget stack: a budget ring with one big number, a compact file list with
// a status dot per row, and a "Processing" card that only shows up when
// there's actually something running or waiting.
//
// Layout: the budget card is intrinsically sized, the files card takes
// whatever height is left (Expanded), and the processing card — when
// visible — sits below it sized to its own (capped) content. Each card has
// its own ListenableBuilder scoped to only the services it reads, so an
// unrelated notifyListeners() (e.g. the scheduler ticking) doesn't rebuild
// the budget or files cards.
import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';
import '../../../core/scheduler.dart';
import '../../../core/util.dart';
import '../../primitives/primitives.dart';
import '../tutorial/tutorial_targets.dart';

/// Rendered height of a single-line [ZRow] (title only, no subtitle).
const double _kFileRowExtent = 44;

/// Fits as many [items] as will render in [maxHeight] at [rowExtent] per
/// row. If not everything fits, one row's worth of space is reserved for an
/// overflow "+N more" line.
({List<T> visible, int overflow}) _fitRows<T>(
  List<T> items,
  double maxHeight,
  double rowExtent,
) {
  final maxRows = maxHeight <= 0 ? 0 : (maxHeight / rowExtent).floor();
  if (items.length <= maxRows) {
    return (visible: items, overflow: 0);
  }
  final showCount = (maxRows - 1).clamp(0, items.length);
  return (visible: items.take(showCount).toList(), overflow: items.length - showCount);
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return ListenableBuilder(
      listenable: s.scheduler,
      builder: (context, _) {
        final hasProcessing = s.scheduler.open.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BudgetCard(s: s),
            const SizedBox(height: ZLayout.cardGap),
            Expanded(child: _FilesCard(s: s)),
            if (hasProcessing) ...[
              const SizedBox(height: ZLayout.cardGap),
              _ProcessingCard(s: s),
            ],
          ],
        );
      },
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.s});

  final AppServices s;

  static const double _ringSize = 64;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s.budget,
      builder: (context, _) {
        final budget = s.budget;
        final pct = (budget.fraction * 100).round();
        return ZCard(
          key: TutorialTargets.budget,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget', style: context.type.titleMedium),
                  ZBadge(label: budget.useOwnKey ? 'Your key' : budget.plan.name),
                ],
              ),
              const SizedBox(height: ZSpace.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label: '$pct percent of monthly budget used',
                    excludeSemantics: true,
                    child: ZRing(fraction: budget.fraction, size: _ringSize),
                  ),
                  const SizedBox(width: ZSpace.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${formatTokens(budget.remaining)} left',
                          style: context.type.displaySmall,
                        ),
                        const SizedBox(height: ZSpace.s4),
                        Text(
                          'of ${formatTokens(budget.limit)} this month',
                          style: context.type.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ZSpace.s12),
              Text(
                '${formatTokens(budget.sessionUsed)} used this session',
                style: context.type.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilesCard extends StatelessWidget {
  const _FilesCard({required this.s});

  final AppServices s;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([s.courses, s.session, s.cache]),
      builder: (context, _) {
        final z = context.z;
        final course = s.courses.byId(s.session.courseId) ??
            (s.courses.courses.isNotEmpty ? s.courses.courses.first : null);
        final saved = s.cache.tokensSaved;

        return ZCard(
          key: TutorialTargets.files,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Files', style: context.type.titleMedium),
              const SizedBox(height: ZSpace.s12),
              Expanded(
                child: course == null
                    ? Center(child: Text('No course selected', style: context.type.bodySmall))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final fit = _fitRows(
                            course.files,
                            constraints.maxHeight,
                            _kFileRowExtent,
                          );
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final f in fit.visible) _FileRow(s: s, file: f),
                              if (fit.overflow > 0)
                                Text('+${fit.overflow} more', style: context.type.bodySmall),
                            ],
                          );
                        },
                      ),
              ),
              if (saved > 0) ...[
                const SizedBox(height: ZSpace.s12),
                Text(
                  'Saved ${formatTokens(saved)} this session',
                  style: context.type.bodySmall?.copyWith(color: z.successText),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.s, required this.file});

  final AppServices s;
  final CourseFile file;

  @override
  Widget build(BuildContext context) {
    final ready = file.status == FileStatus.ready;
    final included = ready && !s.session.excludedFileIds.contains(file.id);

    return ZRow(
      leading: _StatusDot(status: file.status),
      title: file.name,
      trailing: MergeSemantics(
        child: Semantics(
          checked: included,
          child: ZIconButton(
            icon: included ? Icons.check_circle : Icons.radio_button_unchecked,
            tooltip: included
                ? 'Exclude ${file.name} from context'
                : 'Include ${file.name} in context',
            selected: included,
            onPressed: ready ? () => s.session.toggleFile(file.id) : null,
          ),
        ),
      ),
    );
  }
}

/// Tiny status indicator that replaces text like "14.2k · Queued": a
/// colored dot for settled states, a small spinner while a file is
/// actively being processed.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final FileStatus status;

  String get _label => switch (status) {
        FileStatus.ready => 'Ready',
        FileStatus.queued => 'Queued',
        FileStatus.processing => 'Processing',
        FileStatus.unprocessed => 'Not processed',
        FileStatus.failed => 'Failed',
      };

  @override
  Widget build(BuildContext context) {
    if (status == FileStatus.processing) {
      return Semantics(label: _label, child: const ZSpinner(size: 10));
    }
    final z = context.z;
    final color = switch (status) {
      FileStatus.ready => z.success,
      FileStatus.queued => z.textTertiary,
      FileStatus.failed => z.danger,
      FileStatus.unprocessed => z.textTertiary,
      FileStatus.processing => z.accent,
    };
    return Semantics(
      label: _label,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard({required this.s});

  final AppServices s;

  static const int _maxVisible = 3;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s.scheduler,
      builder: (context, _) {
        final scheduler = s.scheduler;
        final policy = scheduler.policy;
        final open = scheduler.open.toList();
        final visible = open.take(_maxVisible).toList();
        final overflow = open.length - visible.length;

        return ZCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Processing', style: context.type.titleMedium),
                  ZIconButton(
                    icon: policy.simulateOffPeak ? Icons.bedtime : Icons.bedtime_outlined,
                    tooltip: 'Simulate off-peak (demo control)',
                    selected: policy.simulateOffPeak,
                    onPressed: () => scheduler.setSimulateOffPeak(!policy.simulateOffPeak),
                  ),
                ],
              ),
              const SizedBox(height: ZSpace.s12),
              for (final job in visible) _JobRow(s: s, job: job),
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.only(top: ZSpace.s4),
                  child: Text('+$overflow more', style: context.type.bodySmall),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.s, required this.job});

  final AppServices s;
  final Job job;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final running = job.state == JobState.running;
    final canPrioritize = !running && job.lane == JobLane.background;

    return ZRow(
      leading: Icon(
        job.lane == JobLane.interactive ? Icons.bolt : Icons.nightlight_round,
        size: ZIcon.md,
        color: z.textSecondary,
      ),
      title: job.label,
      subtitle: running ? null : job.waitReason,
      trailing: running
          ? const ZSpinner()
          : canPrioritize
              ? ZButton(
                  label: 'Process now',
                  onPressed: () => s.scheduler.prioritize(job),
                  variant: ZButtonVariant.tonal,
                  size: ZButtonSize.sm,
                )
              : null,
    );
  }
}
