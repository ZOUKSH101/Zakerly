import '../../../core/app_services.dart';

/// Pulls courses from Canvas, opens the first one if nothing is selected,
/// then starts getting ready every course the plan allows.
///
/// Shared by the Sync button in the course rail and by the workspace, which
/// runs it once on sign-in so the demo (and the first-run tour) lands on a
/// real course list instead of an empty one.
Future<void> syncAndStartCourses(AppServices s) async {
  await s.courses.sync();
  final courses = s.courses.courses;
  if (courses.isEmpty) return;

  final current = s.session.courseId;
  if (current == null || s.courses.byId(current) == null) {
    s.session.selectCourse(courses.first.id);
  }

  for (final course in courses) {
    if (!course.hasStarted && s.ingestion.canIndex(course)) {
      s.ingestion.indexCourse(course);
    }
  }
}
