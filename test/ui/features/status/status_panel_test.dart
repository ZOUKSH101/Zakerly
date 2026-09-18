import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zakerly/core/app_services.dart';
import 'package:zakerly/core/models.dart';
import 'package:zakerly/core/scheduler.dart';
import 'package:zakerly/ui/features/status/status_panel.dart';
import 'package:zakerly/ui/theme.dart';

Widget _harness(AppServices s) {
  return MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Services(
      services: s,
      child: const Scaffold(
        body: SizedBox(width: 320, height: 720, child: StatusPanel()),
      ),
    ),
  );
}

void main() {
  testWidgets('budget card shows one big number, a plan pill, and no extra rows', (tester) async {
    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);

    await tester.pumpWidget(_harness(s));
    await tester.pump();

    expect(find.text('250k left'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('New animations today'), findsNothing);
    expect(find.textContaining('Saved by cache'), findsNothing);
  });

  testWidgets('budget pill switches to Your key under BYOK', (tester) async {
    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);
    s.budget.setUseOwnKey(true);

    await tester.pumpWidget(_harness(s));
    await tester.pump();

    expect(find.text('Your key'), findsOneWidget);
    expect(find.text('Free'), findsNothing);
  });

  testWidgets('files card lists files with a single toggle and no old status text', (
    tester,
  ) async {
    final ready = CourseFile(id: 'f1', courseId: 'c1', name: 'Syllabus.pdf', kind: 'pdf', sourceTokens: 14200)
      ..status = FileStatus.ready;
    final processing =
        CourseFile(id: 'f2', courseId: 'c1', name: 'Lecture 3.pdf', kind: 'slides', sourceTokens: 8000)
          ..status = FileStatus.processing;
    final course = Course(id: 'c1', code: 'CS101', name: 'Intro', term: 'Fall', files: [ready, processing]);

    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);
    s.courses.courses = [course];
    s.session.selectCourse(course.id);

    await tester.pumpWidget(_harness(s));
    await tester.pump();

    expect(find.text('Syllabus.pdf'), findsOneWidget);
    expect(find.text('Lecture 3.pdf'), findsOneWidget);
    // The old verbose subtitle ("14.2k Â· Queued"/"Indexed") is gone.
    expect(find.textContaining('Queued'), findsNothing);
    expect(find.textContaining('Indexed'), findsNothing);
    expect(find.textContaining('14.2k'), findsNothing);
    // "Index" is banned from the UI entirely.
    expect(find.textContaining(RegExp('index', caseSensitive: false)), findsNothing);

    final toggle = find.byIcon(Icons.check_circle);
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(s.session.excludedFileIds.contains('f1'), isTrue);
  });

  testWidgets('processing card is hidden with nothing running or waiting', (tester) async {
    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);

    await tester.pumpWidget(_harness(s));
    await tester.pump();

    expect(find.text('Processing'), findsNothing);
  });

  testWidgets('processing card appears with a Process now button on the Free plan', (
    tester,
  ) async {
    final s = AppServices.demo();
    // Deterministic "waiting" state, independent of the real wall clock.
    s.scheduler.policy.maxConcurrent = 0;

    await tester.pumpWidget(_harness(s));
    await tester.pump();

    final job = s.scheduler.submit(
      label: 'Course notes',
      lane: JobLane.background,
      estimatedTokens: 10,
      run: () async => 10,
    );
    await tester.pump();

    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('Process now'), findsOneWidget);
    expect(find.text('Pro'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);

    await tester.tap(find.text('Process now'));
    await tester.pump();

    expect(job.lane, JobLane.interactive);
    expect(find.text('Process now'), findsNothing);

    // The job never gets a slot (maxConcurrent = 0), so stop the pacing
    // timer before the binding checks for pending timers.
    s.scheduler.dispose();
  });
}
