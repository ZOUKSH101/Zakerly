import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zakerly/core/app_services.dart';
import 'package:zakerly/core/budget.dart';
import 'package:zakerly/core/models.dart';
import 'package:zakerly/core/preferences.dart';
import 'package:zakerly/core/prompts.dart';
import 'package:zakerly/l10n/strings.dart';
import 'package:zakerly/ui/features/courses/course_rail.dart';
import 'package:zakerly/ui/features/settings/settings_dialog.dart';
import 'package:zakerly/ui/features/status/status_panel.dart';
import 'package:zakerly/ui/features/study/study_panel.dart';
import 'package:zakerly/ui/features/tutorial/tutorial.dart';
import 'package:zakerly/ui/features/tutorial/tutorial_targets.dart';
import 'package:zakerly/ui/theme.dart';

/// The wide workspace layout (lib/ui/workspace.dart imports the web-only
/// animation iframe, so VM tests compose the same three panels directly).
class _WideShell extends StatelessWidget {
  const _WideShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 272, child: CourseRail(onOpenSettings: () {})),
          Expanded(child: StudyPanel(onVisualize: (_, _) {}, onOpenStatus: () {})),
          const SizedBox(width: 320, child: StatusPanel()),
        ],
      ),
    );
  }
}

/// The same MaterialApp wiring as app.dart, pinned to Arabic.
Widget _arabicApp(AppServices s, Widget home) {
  return Services(
    services: s,
    child: MaterialApp(
      theme: buildTheme(Brightness.light, arabic: true),
      locale: AppLanguage.arabic.locale,
      supportedLocales: [for (final l in AppLanguage.values) l.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    ),
  );
}

Course _demoCourse() {
  final ready = CourseFile(id: 'f1', courseId: 'c1', name: 'Week 3 - Trees.pdf', kind: 'pdf', sourceTokens: 900)
    ..status = FileStatus.ready
    ..chunks = const [
      Chunk(
        fileId: 'f1',
        fileName: 'Week 3 - Trees.pdf',
        heading: 'What is a binary search tree',
        text: 'A binary search tree keeps smaller keys on the left. Larger keys go right.',
      ),
      Chunk(
        fileId: 'f1',
        fileName: 'Week 3 - Trees.pdf',
        heading: 'Searching a BST',
        text: 'Searching compares the key with each node. It takes O(h) steps.',
      ),
    ];
  final notYet = CourseFile(id: 'f2', courseId: 'c1', name: 'Week 4 - Heaps.pdf', kind: 'pdf', sourceTokens: 900);
  return Course(id: 'c1', code: 'CS201', name: 'Data Structures', term: 'Fall 2026', files: [ready, notYet]);
}

void main() {
  // Real metrics (Readex Pro draws Arabic too), so overflow checks mean
  // something.
  setUpAll(() async {
    final bytes = File('assets/fonts/ReadexPro-Variable.ttf').readAsBytesSync();
    final loader = FontLoader(ZType.fontFamily)
      ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    await loader.load();
  });

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('the one-screen workspace renders in Arabic, right to left, with no English labels', (
    tester,
  ) async {
    await setSize(tester, const Size(1440, 900));
    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);
    s.preferences.setLanguage(AppLanguage.arabic);
    final course = _demoCourse();
    s.courses.courses = [course];
    s.session.selectCourse(course.id);

    await tester.pumpWidget(_arabicApp(s, const _WideShell()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);

    // Direction flips for the whole tree.
    expect(Directionality.of(tester.element(find.byType(StudyPanel))), TextDirection.rtl);

    // Arabic reading order: course rail on the right, Status on the left.
    final railX = tester.getCenter(find.byType(CourseRail)).dx;
    final studyX = tester.getCenter(find.byType(StudyPanel)).dx;
    final statusX = tester.getCenter(find.byType(StatusPanel)).dx;
    expect(railX, greaterThan(studyX));
    expect(studyX, greaterThan(statusX));

    const ar = S.ar;
    for (final text in [
      ar.homeTitle,
      ar.modeLabel(StudyMode.explain),
      ar.modeLabel(StudyMode.socratic),
      ar.modeLabel(StudyMode.quiz),
      ar.starterSummary,
      ar.starterQuiz,
      ar.starterHardest,
      ar.budget,
      ar.files,
      ar.sync,
      ar.planName(s.budget.tier),
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.text('اشرحلي'), findsOneWidget);
    expect(find.text('هنذاكر إيه النهارده؟'), findsOneWidget);
    expect(find.text(ar.composerUsingFiles(1)), findsOneWidget);
    expect(find.text('بستخدم ملف واحد. اختار الملفات من على الشمال.'), findsOneWidget);

    // Nothing from the English table leaks into the key labels.
    for (final english in [
      'What are we studying today?',
      'Explain',
      'Guide me',
      'Quiz me',
      'Sum up the main ideas',
      'Budget',
      'Files',
      'Sync',
      'Free',
      'Not synced yet',
      'Ask about CS201…',
    ]) {
      expect(find.text(english), findsNothing, reason: english);
    }
    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.byTooltip(ar.settings), findsOneWidget);
    expect(find.byTooltip('Send'), findsNothing);
    expect(find.byTooltip(ar.send), findsOneWidget);

    // The mode thumb sits under the first (rightmost) label in RTL.
    final explainX = tester.getCenter(find.text('اشرحلي')).dx;
    final quizX = tester.getCenter(find.text('امتحنّي')).dx;
    expect(explainX, greaterThan(quizX));
  });

  testWidgets('settings reads in Arabic and every section still fits', (tester) async {
    await setSize(tester, const Size(1440, 900));
    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);

    await tester.pumpWidget(_arabicApp(
      s,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => showSettingsDialog(context), child: const Text('open')),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    const ar = S.ar;
    expect(find.text(ar.settings), findsOneWidget);
    expect(find.text(ar.appearance), findsOneWidget);
    expect(find.text(ar.language), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Language'), findsNothing);
    // Language names always appear in their own script.
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);

    for (final section in [ar.sectionPlan, ar.sectionKeys, ar.sectionAccount, ar.sectionGeneral]) {
      await tester.tap(find.text(section).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: section);
    }
    await tester.tap(find.text(ar.sectionPlan).first);
    await tester.pumpAndSettle();
    expect(find.text(ar.planName(PlanTier.free)), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('2 Canvas courses'), findsNothing);
    expect(find.text('مادتين من Canvas'), findsOneWidget);
  });

  testWidgets('the tour speaks Arabic', (tester) async {
    await tester.pumpWidget(_arabicApp(
      AppServices.demo(),
      Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              ElevatedButton(onPressed: () => showTutorial(context), child: const Text('replay')),
              Container(key: TutorialTargets.sync, width: 40, height: 40, color: Colors.blue),
              Container(key: TutorialTargets.courses, width: 40, height: 40, color: Colors.red),
            ],
          ),
        ),
      ),
    ));
    await tester.tap(find.text('replay'));
    await tester.pumpAndSettle();

    expect(find.text('موادك وصلت'), findsOneWidget);
    expect(find.text('خطوة 1 من 2'), findsOneWidget);
    expect(find.text(S.ar.next), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Skip'), findsNothing);

    // In Arabic the left arrow moves forward.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('اختار مادة'), findsOneWidget);
    expect(find.text(S.ar.done), findsOneWidget);
  });

  group('tutor in Arabic', () {
    test('the system prompt asks for Arabic only when the app is in Arabic', () {
      final course = _demoCourse();
      expect(Prompts.tutorSystem(course, StudyMode.explain), isNot(contains('LANGUAGE: ARABIC')));
      expect(
        Prompts.tutorSystem(course, StudyMode.explain, language: AppLanguage.arabic),
        contains(Prompts.arabicReplyLine),
      );
    });

    test('an Arabic starter finds material and the mock answers in Arabic with citations', () async {
      final s = AppServices.demo();
      addTearDown(s.scheduler.dispose);
      s.preferences.setLanguage(AppLanguage.arabic);
      final course = _demoCourse();
      s.courses.courses = [course];

      await s.tutor.ask(course, {'f1'}, S.ar.starterSummary, StudyMode.explain);
      final reply = s.tutor.thread(course.id).last;
      expect(reply.pending, isFalse);
      expect(reply.failed, isFalse);
      expect(reply.notice, isNull);
      expect(reply.text, startsWith('باختصار'));
      expect(reply.text, contains('[Week 3 - Trees.pdf · '));
      expect(reply.citations, isNotEmpty);
    });

    test('a question with no match becomes a notice the UI words in Arabic', () async {
      final s = AppServices.demo();
      addTearDown(s.scheduler.dispose);
      final course = _demoCourse();
      await s.tutor.ask(course, {'f1'}, 'zzz qqq', StudyMode.explain);
      final reply = s.tutor.thread(course.id).last;
      expect(reply.notice, TutorNotice.notFound);
      expect(S.ar.tutorNotice(reply.notice!), startsWith('ملقتش ده في ملفاتك'));
    });
  });

  test('Arabic counting agrees with the number', () {
    expect(S.ar.composerUsingFiles(1), startsWith('بستخدم ملف واحد'));
    expect(S.ar.composerUsingFiles(2), startsWith('بستخدم ملفين'));
    expect(S.ar.composerUsingFiles(3), startsWith('بستخدم 3 ملفات'));
    expect(S.ar.composerUsingFiles(12), startsWith('بستخدم 12 ملف'));
    expect(S.en.composerUsingFiles(1), 'Using 1 file. Pick files on the right.');
    expect(S.en.composerUsingFiles(3), 'Using 3 files. Pick files on the right.');
  });
}
