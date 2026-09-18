import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zakerly/core/app_services.dart';
import 'package:zakerly/core/models.dart';
import 'package:zakerly/core/scheduler.dart';
import 'package:zakerly/ui/features/study/study_panel.dart';
import 'package:zakerly/ui/features/tutorial/tutorial_targets.dart';
import 'package:zakerly/ui/primitives/primitives.dart';

Widget _harness(AppServices s, {void Function(Course, String)? onVisualize}) {
  return MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Services(
      services: s,
      child: Scaffold(
        body: SizedBox(
          width: 900,
          height: 700,
          child: StudyPanel(onVisualize: onVisualize ?? (_, _) {}),
        ),
      ),
    ),
  );
}

Course _course({required String id, required String code, required List<CourseFile> files}) {
  return Course(id: id, code: code, name: '$code course', term: 'Fall 2026', files: files);
}

void main() {
  testWidgets('no courses yet: shows the sync empty state, no chat, no composer', (tester) async {
    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);

    await tester.pumpWidget(_harness(s));
    await tester.pump();

    expect(find.text('Sync your courses to start'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining(RegExp('index', caseSensitive: false)), findsNothing);
  });

  testWidgets(
    'course with no ready files still shows the chat: greeting, chips, a working composer '
    'and a getting-ready note (never a full-screen empty state, never the word index)',
    (tester) async {
      final file = CourseFile(id: 'f1', courseId: 'c1', name: 'Week 1.pdf', kind: 'pdf', sourceTokens: 100)
        ..status = FileStatus.processing;
      final course = _course(id: 'c1', code: 'CS1', files: [file]);

      final s = AppServices.demo();
      addTearDown(s.scheduler.dispose);
      s.courses.courses = [course];
      s.session.selectCourse(course.id);

      await tester.pumpWidget(_harness(s));
      await tester.pump();

      expect(
        find.text('Hi! Ask me anything about CS1. I\'ll answer using your course files.'),
        findsOneWidget,
      );
      expect(find.text('Summarize the key ideas'), findsOneWidget);
      expect(find.text('Quiz me on this week'), findsOneWidget);
      expect(find.text('Explain the hardest concept'), findsOneWidget);

      expect(
        find.text('Getting CS1 ready. You can ask about the files that are done.'),
        findsOneWidget,
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isTrue);

      expect(find.textContaining(RegExp('index', caseSensitive: false)), findsNothing);

      await tester.tap(find.text('Quiz me on this week'));
      await tester.pump();
      final updated = tester.widget<TextField>(find.byType(TextField));
      expect(updated.controller!.text, 'Quiz me on this week');
    },
  );

  testWidgets('Process now promotes the course\'s open background job to the live lane', (
    tester,
  ) async {
    final file = CourseFile(id: 'f1', courseId: 'c1', name: 'Notes.pdf', kind: 'pdf', sourceTokens: 100)
      ..status = FileStatus.queued;
    final course = _course(id: 'c1', code: 'CS1', files: [file]);

    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);
    s.courses.courses = [course];
    s.session.selectCourse(course.id);
    // Deterministic "waiting" state, independent of the real wall clock.
    s.scheduler.policy.maxConcurrent = 0;
    final job = s.scheduler.submit(
      label: 'Process Notes.pdf',
      lane: JobLane.background,
      estimatedTokens: 10,
      run: () async => 10,
    );

    await tester.pumpWidget(_harness(s));
    await tester.pump();

    expect(find.text('Process now'), findsOneWidget);
    await tester.tap(find.text('Process now'));
    await tester.pump();

    expect(job.lane, JobLane.interactive);
  });

  testWidgets('tutorial anchors are attached to the mode switch, composer and visualize control', (
    tester,
  ) async {
    final file = CourseFile(id: 'f1', courseId: 'c1', name: 'Week 1.pdf', kind: 'pdf', sourceTokens: 100)
      ..status = FileStatus.ready;
    final course = _course(id: 'c1', code: 'CS1', files: [file]);

    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);
    s.courses.courses = [course];
    s.session.selectCourse(course.id);

    await tester.pumpWidget(_harness(s));
    await tester.pump();

    expect(find.byKey(TutorialTargets.modes), findsOneWidget);
    expect(find.byKey(TutorialTargets.composer), findsOneWidget);
    expect(find.byKey(TutorialTargets.visualize), findsOneWidget);
  });

  testWidgets(
    'visualize control stays disabled until there is a finished tutor answer, then hands '
    'the prior question back as the concept',
    (tester) async {
      final file = CourseFile(id: 'f1', courseId: 'c1', name: 'Week 1.pdf', kind: 'pdf', sourceTokens: 100)
        ..status = FileStatus.ready;
      final course = _course(id: 'c1', code: 'CS1', files: [file]);

      final s = AppServices.demo();
      addTearDown(s.scheduler.dispose);
      s.courses.courses = [course];
      s.session.selectCourse(course.id);

      Course? visualizedCourse;
      String? visualizedConcept;

      await tester.pumpWidget(_harness(
        s,
        onVisualize: (c, concept) {
          visualizedCourse = c;
          visualizedConcept = concept;
        },
      ));
      await tester.pump();

      var button = tester.widget<ZIconButton>(find.byKey(TutorialTargets.visualize));
      expect(button.onPressed, isNull);

      final thread = s.tutor.thread(course.id);
      thread.add(ChatMessage(author: Author.student, text: 'What is a BST?'));
      thread.add(ChatMessage(author: Author.tutor, text: 'A binary search tree keeps order.'));
      s.courses.touch(); // forces the panel to rebuild and read the thread again.
      await tester.pump();

      button = tester.widget<ZIconButton>(find.byKey(TutorialTargets.visualize));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byKey(TutorialTargets.visualize));
      await tester.pump();

      expect(visualizedCourse?.id, course.id);
      expect(visualizedConcept, 'What is a BST?');
    },
  );

  testWidgets('sending a question works even with no ready files (no tokens are spent)', (
    tester,
  ) async {
    final file = CourseFile(id: 'f1', courseId: 'c1', name: 'Week 1.pdf', kind: 'pdf', sourceTokens: 100)
      ..status = FileStatus.processing;
    final course = _course(id: 'c1', code: 'CS1', files: [file]);

    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);
    s.courses.courses = [course];
    s.session.selectCourse(course.id);

    await tester.pumpWidget(_harness(s));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'What is on the syllabus?');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    final thread = s.tutor.thread(course.id);
    expect(thread.length, 2);
    expect(thread.first.author, Author.student);
    expect(thread.first.text, 'What is on the syllabus?');
    expect(thread.last.author, Author.tutor);
    expect(thread.last.pending, isFalse);
  });
}
