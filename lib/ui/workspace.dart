// The one-screen responsive workspace shell (see CONTRACT.md "Hard layout
// rule"). Composes the feature panels; owns no business logic itself.
//
//   >=1100px : Row[ CourseRail(272) | StudyPanel(flex) | StatusPanel(344) ]
//   800-1099 : Row[ CourseRail(248) | StudyPanel(flex) ], StatusPanel as an
//              end drawer opened from a toggle StudyPanel exposes.
//   <800     : bottom tabs (Courses / Study / Status).
//
// No page-level scrolling is introduced here; each panel manages its own.
//
// RTL (Arabic): the Rows mirror on their own, so the course rail sits on the
// right, the chat in the middle and Status on the left, which is the
// right-to-left reading order. The end drawer opens from the left.
import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/models.dart';
import '../l10n/strings.dart';
import 'features/animation/animation_window.dart';
import 'features/courses/course_rail.dart';
import 'features/courses/course_sync.dart';
import 'features/settings/settings_dialog.dart';
import 'features/status/status_panel.dart';
import 'features/study/study_panel.dart';
import 'features/tutorial/tutorial.dart';

/// Breakpoints from CONTRACT.md.
class _Breakpoints {
  _Breakpoints._();
  static const double wide = 1100;
  static const double medium = 800;
}

class Workspace extends StatefulWidget {
  const Workspace({super.key});

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _studyKey = GlobalKey(debugLabel: 'workspace.study');
  int _tabIndex = 1; // Courses / Study / Status -> default to Study.

  @override
  void initState() {
    super.initState();
    // After the first frame: land on a synced course list (so nobody starts
    // on an empty rail), then show the tour once per browser. Syncing first
    // means every tour step has a real target: courses, files, the composer.
    WidgetsBinding.instance.addPostFrameCallback((_) => _landAndTour());
  }

  Future<void> _landAndTour() async {
    if (!mounted) return;
    final s = Services.of(context);
    if (s.courses.courses.isEmpty && !s.courses.syncing) {
      await syncAndStartCourses(s);
    }
    if (!mounted) return;
    await maybeShowTutorial(context);
  }

  void _openSettings() => showSettingsDialog(context);

  void _visualize(Course course, String concept) {
    showAnimationWindow(context, course: course, concept: concept);
  }

  @override
  Widget build(BuildContext context) {
    // One Scaffold for every width, and the chat keeps a GlobalKey, so
    // crossing a breakpoint moves the StudyPanel instead of rebuilding it:
    // the draft, scroll position and focus survive a window resize.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layout = width >= _Breakpoints.wide
            ? _Layout.wide
            : (width >= _Breakpoints.medium ? _Layout.medium : _Layout.narrow);
        final study = StudyPanel(
          key: _studyKey,
          onVisualize: _visualize,
          onOpenStatus: switch (layout) {
            _Layout.wide => null,
            _Layout.medium => () => _scaffoldKey.currentState?.openEndDrawer(),
            _Layout.narrow => () => setState(() => _tabIndex = 2),
          },
          budgetPillTarget: layout == _Layout.narrow,
        );
        return Scaffold(
          key: _scaffoldKey,
          endDrawer: layout == _Layout.medium
              ? const Drawer(
                  width: 344,
                  child: SafeArea(child: StatusPanel()),
                )
              : null,
          body: switch (layout) {
            _Layout.wide => _buildWide(study),
            _Layout.medium => _buildMedium(study),
            _Layout.narrow => _buildNarrow(study),
          },
          bottomNavigationBar: layout == _Layout.narrow ? _buildTabs(context) : null,
        );
      },
    );
  }

  Widget _buildWide(Widget study) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 272, child: CourseRail(onOpenSettings: _openSettings)),
        Expanded(child: study),
        const SizedBox(width: 344, child: StatusPanel()),
      ],
    );
  }

  Widget _buildMedium(Widget study) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 248, child: CourseRail(onOpenSettings: _openSettings)),
        Expanded(child: study),
      ],
    );
  }

  Widget _buildNarrow(Widget study) {
    final pages = <Widget>[
      // Picking a course on the Courses tab takes you to the chat for it.
      CourseRail(
        onOpenSettings: _openSettings,
        onCourseSelected: () => setState(() => _tabIndex = 1),
      ),
      study,
      // The Status tab is hidden most of the time, so the tour points at
      // the chat's budget pill instead (one budget anchor at a time).
      const StatusPanel(budgetTarget: false),
    ];
    return SafeArea(
      child: IndexedStack(index: _tabIndex, children: pages),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final t = S.of(context);
    return NavigationBar(
      selectedIndex: _tabIndex,
      onDestinationSelected: (i) => setState(() => _tabIndex = i),
      destinations: [
        NavigationDestination(icon: const Icon(Icons.school_outlined), label: t.navCourses),
        NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), label: t.navStudy),
        NavigationDestination(icon: const Icon(Icons.insights_outlined), label: t.navStatus),
      ],
    );
  }
}

enum _Layout { wide, medium, narrow }
