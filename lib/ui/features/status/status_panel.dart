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
import '../../../l10n/strings.dart';
import '../../primitives/primitives.dart';
import '../tutorial/tutorial_targets.dart';

/// File names wrap to at most this many lines.
const int _kFileTitleLines = 2;

/// Height reserved for the "+N more" line.
const double _kMoreExtent = 24;

/// Fits as many [items] as will render in [maxHeight], given each row's own
/// [extents]. If not everything fits, room is reserved for a "+N more" line.
({List<T> visible, int overflow}) _fitRows<T>(
  List<T> items,
  List<double> extents,
  double maxHeight,
) {
  final total = extents.fold<double>(0, (a, b) => a + b);
  if (total <= maxHeight) return (visible: items, overflow: 0);
  var used = 0.0;
  var count = 0;
  while (count < items.length && used + extents[count] + _kMoreExtent <= maxHeight) {
    used += extents[count];
    count++;
  }
  return (visible: items.take(count).toList(), overflow: items.length - count);
}

/// Measures how tall each file row will be: one or two lines of title.
List<double> _fileRowExtents(BuildContext context, List<CourseFile> files, double rowWidth) {
  final style = context.type.bodyLarge;
  final titleWidth = rowWidth -
      ZRow.chromeWidth(leading: true, trailing: true) -
      ZStatusDot.slot -
      ZLayout.iconButtonSize;
  final direction = Directionality.of(context);
  final scaler = MediaQuery.textScalerOf(context);
  return [
    for (final f in files)
      () {
        final painter = TextPainter(
          text: TextSpan(text: f.name, style: style),
          maxLines: _kFileTitleLines,
          textDirection: direction,
          textScaler: scaler,
        )..layout(maxWidth: titleWidth <= 0 ? 1 : titleWidth);
        final h = painter.height + ZRow.verticalPadding;
        painter.dispose();
        return h < ZRow.minExtent ? ZRow.minExtent : h;
      }(),
  ];
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key, this.budgetTarget = true});

  /// Whether the budget card carries [TutorialTargets.budget]. Off on
  /// phones, where the Status tab is hidden and the tour lights the chat's
  /// budget pill instead, so only one budget anchor is ever mounted.
  final bool budgetTarget;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return Padding(
      padding: const EdgeInsets.all(ZLayout.panelPadding),
      child: ListenableBuilder(
        listenable: s.scheduler,
        builder: (context, _) {
          final hasProcessing = s.scheduler.open.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BudgetCard(s: s, target: budgetTarget),
              const SizedBox(height: ZLayout.cardGap),
              Expanded(child: _FilesCard(s: s)),
              if (hasProcessing) ...[
                const SizedBox(height: ZLayout.cardGap),
                _ProcessingCard(s: s),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.s, required this.target});

  final AppServices s;
  final bool target;

  static const double _ringSize = 64;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s.budget,
      builder: (context, _) {
        final budget = s.budget;
        final t = S.of(context);
        final pct = (budget.fraction * 100).round();
        return ZCard(
          key: target ? TutorialTargets.budget : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        t.budget,
                        style: context.type.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ZBadge(label: budget.useOwnKey ? t.yourKey : t.planName(budget.tier)),
                ],
              ),
              const SizedBox(height: ZSpace.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label: t.budgetUsedSemantics(pct),
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
                          t.tokensLeft(formatTokens(budget.remaining)),
                          style: context.type.displaySmall,
                        ),
                        const SizedBox(height: ZSpace.s4),
                        Text(
                          t.ofThisMonth(formatTokens(budget.limit)),
                          style: context.type.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ZSpace.s12),
              Text(
                t.usedThisSession(formatTokens(budget.sessionUsed)),
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
        final t = S.of(context);
        final course = s.courses.byId(s.session.courseId) ??
            (s.courses.courses.isNotEmpty ? s.courses.courses.first : null);
        final saved = s.cache.tokensSaved;

        return ZCard(
          key: TutorialTargets.files,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(header: true, child: Text(t.files, style: context.type.titleMedium)),
              const SizedBox(height: ZSpace.s12),
              Expanded(
                child: course == null
                    ? Center(child: Text(t.pickCourseForFiles, style: context.type.bodySmall))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final fit = _fitRows(
                            course.files,
                            _fileRowExtents(context, course.files, constraints.maxWidth),
                            constraints.maxHeight,
                          );
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final f in fit.visible) _FileRow(s: s, file: f),
                              if (fit.overflow > 0)
                                Text(t.more(fit.overflow), style: context.type.bodySmall),
                            ],
                          );
                        },
                      ),
              ),
              if (saved > 0) ...[
                const SizedBox(height: ZSpace.s12),
                Text(
                  t.savedThisSession(formatTokens(saved)),
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
      titleMaxLines: _kFileTitleLines,
      trailing: MergeSemantics(
        child: Semantics(
          checked: included,
          child: ZIconButton(
            icon: included ? Icons.check_circle : Icons.radio_button_unchecked,
            tooltip: included
                ? S.of(context).stopUsingFile(file.name)
                : S.of(context).useFile(file.name),
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

  @override
  Widget build(BuildContext context) {
    final label = S.of(context).fileStatus(status);
    if (status == FileStatus.processing) {
      return Semantics(label: label, child: const ZSpinner(size: ZStatusDot.slot));
    }
    final z = context.z;
    final color = switch (status) {
      FileStatus.ready => z.success,
      FileStatus.queued => z.textTertiary,
      FileStatus.failed => z.danger,
      FileStatus.unprocessed => z.textTertiary,
      FileStatus.processing => z.accent,
    };
    return ZStatusDot(color: color, label: label);
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
        final t = S.of(context);
        final open = scheduler.open.toList();
        final visible = open.take(_maxVisible).toList();
        final overflow = open.length - visible.length;
        // Say why things wait in words, once: under the running rows and the
        // first waiting one. The rest keep it as hover text.
        final firstWaiting = visible.indexWhere((j) => j.state != JobState.running);

        return ZCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        t.inProgress,
                        style: context.type.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ZIconButton(
                    icon: policy.simulateOffPeak ? Icons.bedtime : Icons.bedtime_outlined,
                    tooltip: t.demoNight(policy),
                    selected: policy.simulateOffPeak,
                    onPressed: () => scheduler.setSimulateOffPeak(!policy.simulateOffPeak),
                  ),
                ],
              ),
              const SizedBox(height: ZSpace.s12),
              for (final (i, job) in visible.indexed)
                _JobRow(
                  s: s,
                  job: job,
                  showReason: job.state == JobState.running || i == firstWaiting,
                ),
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.only(top: ZSpace.s4),
                  child: Text(t.more(overflow), style: context.type.bodySmall),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.s, required this.job, required this.showReason});

  static const _processPrefix = 'Process ';

  final AppServices s;
  final Job job;

  /// Show the reason as a one-line subtitle rather than only on hover.
  final bool showReason;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final t = S.of(context);
    final running = job.state == JobState.running;
    final canPrioritize = !running && job.lane == JobLane.background;
    // "Process Week 3 - Trees.pdf" reads as just the file here: the card
    // title already says what's happening.
    final title = job.kind == JobKind.other && job.label.startsWith(_processPrefix)
        ? job.label.substring(_processPrefix.length)
        : t.jobTitle(job);
    final wait = job.waitReason;
    final reason = running
        ? t.workingOnIt
        : (wait == null
            ? t.waiting
            : t.waitReason(wait, requestsPerMinute: s.scheduler.policy.requestsPerMinute));

    return ZRow(
      leading: running
          ? const ZSpinner(size: ZStatusDot.slot)
          : ZStatusDot(color: job.lane == JobLane.interactive ? z.accent : z.textTertiary),
      title: title,
      subtitle: showReason ? reason : null,
      tooltip: showReason ? null : reason,
      trailing: canPrioritize
          ? ZIconButton(
              icon: Icons.fast_forward_rounded,
              mirrorInRtl: true,
              tooltip: t.processNow,
              onPressed: () => s.scheduler.prioritize(job),
            )
          : null,
    );
  }
}
