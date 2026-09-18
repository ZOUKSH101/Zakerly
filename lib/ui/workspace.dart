// The one-screen responsive workspace shell (see CONTRACT.md "Hard layout
// rule"). Composes the feature panels; owns no business logic itself.
//
//   >=1100px : Row[ CourseRail(272) | StudyPanel(flex) | StatusPanel(320) ]
//   800-1099 : Row[ CourseRail(248) | StudyPanel(flex) ], StatusPanel as an
//              end drawer opened from a toggle StudyPanel exposes.
//   <800     : bottom tabs (Courses / Study / Status).
//
// No page-level scrolling is introduced here; each panel manages its own.
import 'package:flutter/material.dart';

import '../core/models.dart';
import 'features/animation/animation_window.dart';
import 'features/courses/course_rail.dart';
import 'features/settings/settings_dialog.dart';
import 'features/status/status_panel.dart';
import 'features/study/study_panel.dart';

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
  int _tabIndex = 1; // Courses / Study / Status -> default to Study.

  void _openSettings() => showSettingsDialog(context);

  void _visualize(Course course, String concept) {
    showAnimationWindow(context, course: course, concept: concept);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= _Breakpoints.wide) return _buildWide(context);
        if (width >= _Breakpoints.medium) return _buildMedium(context);
        return _buildNarrow(context);
      },
    );
  }

  Widget _buildWide(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 272, child: CourseRail(onOpenSettings: _openSettings)),
          Expanded(child: StudyPanel(onVisualize: _visualize)),
          const SizedBox(width: 320, child: StatusPanel()),
        ],
      ),
    );
  }

  Widget _buildMedium(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const Drawer(
        width: 320,
        child: SafeArea(child: StatusPanel()),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 248, child: CourseRail(onOpenSettings: _openSettings)),
          Expanded(
            child: StudyPanel(
              onVisualize: _visualize,
              onOpenStatus: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final pages = <Widget>[
      CourseRail(onOpenSettings: _openSettings),
      StudyPanel(
        onVisualize: _visualize,
        onOpenStatus: () => setState(() => _tabIndex = 2),
      ),
      const StatusPanel(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tabIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Courses'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Status'),
        ],
      ),
    );
  }
}
