import 'dart:async';

import 'package:flutter/foundation.dart';

import 'budget.dart';

/// Interactive = a student is waiting. Background = indexing and other heavy
/// work that can wait for the off-peak window.
enum JobLane { interactive, background }

enum JobState { queued, waiting, running, done, failed }

/// Why a job is still waiting. The UI words it (`S.waitReason`).
enum WaitReason { freeSlot, pacing, liveFirst, quietMoment }

/// What a job is for, so the UI can title it in the student's language
/// (`S.jobTitle`). [other] falls back to the raw [Job.label].
enum JobKind { process, answer, animation, other }

/// Thrown when a job would go over the active budget.
class OutOfBudgetError extends StateError {
  OutOfBudgetError()
      : super("You've used this month's budget. Change your plan or key in Settings to keep going.");
}

class Job {
  Job._(this.id, this.label, this.lane, this.estimatedTokens, this._run, this.kind, this.subject) {
    _completer.future.ignore(); // background jobs may fail with no listener
  }

  /// [label] is the English log line (also used for usage history).
  final String id, label;
  final JobKind kind;

  /// The file name, course code or concept the job is about.
  final String? subject;
  JobLane lane;
  final int estimatedTokens;
  final Future<int> Function() _run;
  final _completer = Completer<void>();
  final DateTime createdAt = DateTime.now();

  JobState state = JobState.queued;
  WaitReason? waitReason;
  String? error;
  int tokensUsed = 0;
  DateTime? finishedAt;

  Future<void> get done => _completer.future;
  bool get isOpen =>
      state == JobState.queued || state == JobState.waiting || state == JobState.running;
}

class SchedulerPolicy {
  int requestsPerMinute = 10;
  int maxConcurrent = 2;
  int offPeakStartHour = 1;
  int offPeakEndHour = 7;

  /// Demo switch: pretend the off-peak window is open now.
  bool simulateOffPeak = false;

  bool isOffPeak(DateTime now) {
    if (simulateOffPeak) return true;
    final h = now.hour;
    return offPeakStartHour <= offPeakEndHour
        ? h >= offPeakStartHour && h < offPeakEndHour
        : h >= offPeakStartHour || h < offPeakEndHour;
  }

  /// Plain-words window, e.g. "1 to 7 am" or "10 pm to 6 am".
  String get windowLabel {
    final start = _hour(offPeakStartHour);
    final end = _hour(offPeakEndHour);
    return start.$2 == end.$2 ? '${start.$1} to ${end.$1} ${end.$2}' : '${start.$1} ${start.$2} to ${end.$1} ${end.$2}';
  }

  static (int, String) _hour(int h) {
    final hh = h % 24;
    final twelve = hh % 12 == 0 ? 12 : hh % 12;
    return (twelve, hh < 12 ? 'am' : 'pm');
  }
}

/// Our own pacing layer in front of every model call. Live questions go
/// first; indexing waits for off-peak hours and never exceeds the request
/// rate, so the provider's limits are respected on our side.
class RequestScheduler extends ChangeNotifier {
  RequestScheduler({required this.budget});

  final BudgetController budget;
  final policy = SchedulerPolicy();

  final List<Job> _jobs = [];
  final List<DateTime> _starts = [];
  Timer? _timer; // Ticks only while jobs are waiting.
  int _seq = 0;

  List<Job> get jobs => List.unmodifiable(_jobs);
  Iterable<Job> get open => _jobs.where((j) => j.isOpen);
  Iterable<Job> get finished => _jobs.where((j) => !j.isOpen);
  int get runningCount => _jobs.where((j) => j.state == JobState.running).length;
  int get requestsThisMinute => _starts.length;

  Job submit({
    required String label,
    required JobLane lane,
    required int estimatedTokens,
    required Future<int> Function() run,
    JobKind kind = JobKind.other,
    String? subject,
  }) {
    final job = Job._('job-${++_seq}', label, lane, estimatedTokens, run, kind, subject);
    _jobs.add(job);
    if (_jobs.length > 80) _jobs.removeWhere((j) => !j.isOpen && _jobs.length > 60);
    notifyListeners();
    _pump();
    return job;
  }

  /// "Process now": move a background job into the live lane. Available on
  /// every plan; Pro only raises the pacing limits.
  void prioritize(Job job) {
    if (!job.isOpen || job.state == JobState.running) return;
    job.lane = JobLane.interactive;
    notifyListeners();
    _pump();
  }

  void setSimulateOffPeak(bool v) {
    policy.simulateOffPeak = v;
    notifyListeners();
    _pump();
  }

  void _pump() {
    final now = DateTime.now();
    _starts.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));

    final waiting = _jobs
        .where((j) => j.state == JobState.queued || j.state == JobState.waiting)
        .toList()
      ..sort((a, b) => a.lane == b.lane
          ? a.createdAt.compareTo(b.createdAt)
          : (a.lane == JobLane.interactive ? -1 : 1));
    final offPeak = policy.isOffPeak(now);
    final liveWaiting = waiting.any((j) => j.lane == JobLane.interactive);

    var changed = false;
    for (final job in waiting) {
      final background = job.lane == JobLane.background;
      final WaitReason? reason;
      if (runningCount >= policy.maxConcurrent) {
        reason = WaitReason.freeSlot;
      } else if (_starts.length >= policy.requestsPerMinute) {
        reason = WaitReason.pacing;
      } else if (background && liveWaiting) {
        reason = WaitReason.liveFirst;
      } else if (background && !offPeak && runningCount > 0) {
        // Outside the off-peak window, background work only runs when the
        // line is quiet, one job at a time.
        reason = WaitReason.quietMoment;
      } else if (!budget.canSpend(job.estimatedTokens)) {
        final err = OutOfBudgetError();
        job
          ..state = JobState.failed
          ..error = err.message
          ..finishedAt = now;
        job._completer.completeError(err);
        changed = true;
        continue;
      } else {
        reason = null;
      }

      if (reason == null) {
        _start(job);
        changed = true;
      } else if (job.state != JobState.waiting || job.waitReason != reason) {
        job
          ..state = JobState.waiting
          ..waitReason = reason;
        changed = true;
      }
    }
    if (changed) notifyListeners();

    final anyWaiting = _jobs.any((j) => j.state == JobState.queued || j.state == JobState.waiting);
    if (anyWaiting) {
      _timer ??= Timer.periodic(const Duration(milliseconds: 400), (_) => _pump());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _start(Job job) {
    job
      ..state = JobState.running
      ..waitReason = null;
    _starts.add(DateTime.now());
    job._run().then((tokens) {
      job
        ..tokensUsed = tokens
        ..state = JobState.done;
      budget.record(job.label, tokens);
      job._completer.complete();
    }, onError: (Object e) {
      job
        ..state = JobState.failed
        ..error = '$e';
      job._completer.completeError(e);
    }).whenComplete(() {
      job.finishedAt = DateTime.now();
      notifyListeners();
      _pump();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
