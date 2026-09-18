// StatusPanel: the right-hand column of the one-screen workspace. Shows the
// month's token budget, which course files feed the tutor's context, and the
// request scheduler's queue. Also used as an end drawer on medium screens.
//
// Layout is tight by construction (budget card is intrinsically sized;
// context/queue split the remaining height 1:1) because at a 320x680
// viewport there is very little room to spare. Each card also has its own
// ListenableBuilder scoped to only the services it reads, so an unrelated
// notifyListeners() (e.g. the scheduler ticking) doesn't rebuild the budget
// or context cards.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';
import '../../../core/scheduler.dart';
import '../../../core/util.dart';
import '../../primitives/primitives.dart';

/// Rendered height of a two-line [ZRow] (title + subtitle, 8px vertical
/// padding each side). Used to compute how many rows fit in the space
/// [LayoutBuilder] hands us, instead of nesting a scrollable ListView.
const double _kRowExtent = 52;

/// Compact card padding: at a 680px-tall panel there's no room for the
/// default 16px ZCard padding across three stacked cards.
const double _kCardPadding = ZSpace.s4;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BudgetCard(s: s),
        const SizedBox(height: ZSpace.s12),
        Expanded(flex: 1, child: _ContextCard(s: s)),
        const SizedBox(height: ZSpace.s12),
        Expanded(flex: 1, child: _QueueCard(s: s)),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.s});

  final AppServices s;

  static const double _ringSize = 56;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([s.budget, s.cache]),
      builder: (context, _) {
        final z = context.z;
        final budget = s.budget;
        final pct = (budget.fraction * 100).round();
        return ZCard(
          padding: _kCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ZEyebrow('BUDGET'),
                  Text(budget.sourceLabel, style: context.type.bodySmall),
                ],
              ),
              const SizedBox(height: ZSpace.s8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label: '$pct percent of monthly budget used',
                    excludeSemantics: true,
                    child: ZRing(
                      fraction: budget.fraction,
                      size: _ringSize,
                      center: Text(
                        '$pct%',
                        style: context.type.labelSmall?.copyWith(color: z.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: ZSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatTokens(budget.remaining), style: context.type.titleLarge),
                        Text(
                          'left of ${formatTokens(budget.limit)} this month',
                          style: context.type.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ZSpace.s8),
              _StatRow(label: 'This session', value: formatTokens(budget.sessionUsed)),
              const SizedBox(height: ZSpace.s4),
              _StatRow(
                label: 'Saved by cache',
                value: formatTokens(s.cache.tokensSaved),
                valueColor: z.success,
              ),
              const SizedBox(height: ZSpace.s4),
              _StatRow(
                label: 'New animations today',
                value: '${budget.animationsToday} / ${budget.plan.animationsPerDay}',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    return Row(
      children: [
        Expanded(child: Text(label, style: context.type.bodySmall)),
        Text(value, style: context.type.labelLarge?.copyWith(color: valueColor ?? z.text)),
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.s});

  final AppServices s;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([s.courses, s.session]),
      builder: (context, _) {
        final course = s.courses.byId(s.session.courseId) ??
            (s.courses.courses.isNotEmpty ? s.courses.courses.first : null);
        final included = course == null ? const <String>{} : s.session.includedFileIds(course);
        final includedTokens = course == null
            ? 0
            : course.files
                .where((f) => included.contains(f.id))
                .fold<int>(0, (sum, f) => sum + f.sourceTokens);

        return ZCard(
          padding: _kCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('In context', style: context.type.titleMedium),
              Text('You decide what the tutor reads', style: context.type.bodySmall),
              const SizedBox(height: ZSpace.s4),
              Expanded(
                child: course == null
                    ? Text('No course selected', style: context.type.bodySmall)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final fit = _fitRows(course.files, constraints.maxHeight, _kRowExtent);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final f in fit.visible) _ContextFileRow(s: s, file: f),
                              if (fit.overflow > 0)
                                Text('+${fit.overflow} more', style: context.type.bodySmall),
                            ],
                          );
                        },
                      ),
              ),
              if (course != null) ...[
                const SizedBox(height: ZSpace.s4),
                Text(
                  'Full files: ~${formatTokens(includedTokens)} tokens',
                  style: context.type.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ContextFileRow extends StatelessWidget {
  const _ContextFileRow({required this.s, required this.file});

  final AppServices s;
  final CourseFile file;

  String _statusWord(FileStatus status) => switch (status) {
        FileStatus.ready => 'Indexed',
        FileStatus.queued => 'Queued',
        FileStatus.processing => 'Indexing…',
        FileStatus.unprocessed => 'Not indexed',
        FileStatus.failed => 'Failed',
      };

  @override
  Widget build(BuildContext context) {
    final ready = file.status == FileStatus.ready;
    final included = ready && !s.session.excludedFileIds.contains(file.id);

    return ZRow(
      title: file.name,
      subtitle: '${formatTokens(file.sourceTokens)} · ${_statusWord(file.status)}',
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

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.s});

  final AppServices s;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([s.scheduler, s.budget]),
      builder: (context, _) {
        final scheduler = s.scheduler;
        final policy = scheduler.policy;
        final open = scheduler.open.toList();

        return ZCard(
          padding: _kCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Queue', style: context.type.titleMedium),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ZIconButton(
                        icon: policy.simulateOffPeak ? Icons.bedtime : Icons.bedtime_outlined,
                        tooltip: 'Simulate off-peak (demo control)',
                        selected: policy.simulateOffPeak,
                        onPressed: () => scheduler.setSimulateOffPeak(!policy.simulateOffPeak),
                      ),
                      const SizedBox(width: ZSpace.s4),
                      _OffPeakBadge(policy: policy),
                    ],
                  ),
                ],
              ),
              Text(
                'Up to ${policy.requestsPerMinute}/min · ${scheduler.runningCount}/'
                '${policy.maxConcurrent} running now',
                style: context.type.bodySmall,
              ),
              const SizedBox(height: ZSpace.s4),
              Expanded(
                child: open.isEmpty
                    ? Text('Nothing waiting', style: context.type.bodySmall)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final fit = _fitRows(open, constraints.maxHeight, _kRowExtent);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final job in fit.visible) _QueueJobRow(s: s, job: job),
                              if (fit.overflow > 0)
                                Text('+${fit.overflow} more', style: context.type.bodySmall),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(height: ZSpace.s4),
              // The scheduler prunes finished jobs once its history exceeds
              // 80 entries, so `finished.length`/summed tokens would silently
              // undercount. Session spend from the budget controller is the
              // reliable running total.
              Semantics(
                liveRegion: true,
                child: Text(
                  'This session: ${formatTokens(s.budget.sessionUsed)} tokens used',
                  style: context.type.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QueueJobRow extends StatelessWidget {
  const _QueueJobRow({required this.s, required this.job});

  final AppServices s;
  final Job job;

  String get _stateLabel {
    final name = job.state.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final running = job.state == JobState.running;
    final waitingBackground = job.state == JobState.waiting && job.lane == JobLane.background;

    Widget? trailing;
    if (running) {
      trailing = const ZSpinner();
    } else if (waitingBackground) {
      trailing = s.budget.plan.priorityProcessing
          ? ZButton(
              label: 'Run now',
              onPressed: () => s.scheduler.prioritize(job),
              variant: ZButtonVariant.tonal,
              size: ZButtonSize.sm,
            )
          : Tooltip(
              message: 'Pro skips the off-peak wait',
              child: ZBadge(icon: Icons.lock_outline, label: 'Pro'),
            );
    }

    return ZRow(
      leading: Icon(
        job.lane == JobLane.interactive ? Icons.bolt : Icons.nightlight_round,
        size: ZIcon.md,
        color: z.textSecondary,
      ),
      title: job.label,
      subtitle: job.waitReason ?? _stateLabel,
      trailing: trailing,
    );
  }
}

/// Off-peak status is a function of the wall clock, not just of scheduler
/// notifications, so it needs its own tick to stay accurate between
/// scheduler-driven rebuilds (e.g. sitting idle across the top of the hour).
class _OffPeakBadge extends StatefulWidget {
  const _OffPeakBadge({required this.policy});

  final SchedulerPolicy policy;

  @override
  State<_OffPeakBadge> createState() => _OffPeakBadgeState();
}

class _OffPeakBadgeState extends State<_OffPeakBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offPeak = widget.policy.isOffPeak(DateTime.now());
    return ZBadge(
      label: offPeak ? 'Off-peak now' : 'Off-peak ${widget.policy.windowLabel}',
      tone: offPeak ? ZBadgeTone.success : ZBadgeTone.neutral,
    );
  }
}
