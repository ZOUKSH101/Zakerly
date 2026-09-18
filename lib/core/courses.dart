import 'package:flutter/foundation.dart';

import 'models.dart';
import 'services.dart';

class CourseRepository extends ChangeNotifier {
  CourseRepository(this.lms);

  final LmsProvider lms;
  List<Course> courses = const [];
  bool syncing = false;
  DateTime? lastSynced;
  String? error;

  Course? byId(String? id) {
    for (final c in courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Pulls courses from the LMS, keeping local indexing state for files we
  /// already know about.
  Future<void> sync() async {
    if (syncing) return;
    syncing = true;
    error = null;
    notifyListeners();
    try {
      final fresh = await lms.listCourses();
      final known = {for (final c in courses) for (final f in c.files) f.id: f};
      courses = [
        for (final c in fresh)
          Course(
            id: c.id,
            code: c.code,
            name: c.name,
            term: c.term,
            files: [for (final f in c.files) known[f.id] ?? f],
          ),
      ];
      lastSynced = DateTime.now();
    } catch (e) {
      debugPrint('Canvas sync failed: $e');
      error = 'Canvas isn\'t answering right now. Try Sync again in a bit.';
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  /// Files mutate in place; this tells listeners to repaint.
  void touch() => notifyListeners();
}
