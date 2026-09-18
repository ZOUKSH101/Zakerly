import 'package:flutter/widgets.dart';

import 'animations.dart';
import 'budget.dart';
import 'cache.dart';
import 'courses.dart';
import 'ingestion.dart';
import 'mock/mock_auth.dart';
import 'mock/mock_canvas.dart';
import 'mock/mock_llm.dart';
import 'models.dart';
import 'preferences.dart';
import 'providers.dart';
import 'scheduler.dart';
import 'services.dart';
import 'tutor.dart';

/// UI state shared across the workspace panels: which course is open, which
/// files the student has excluded from context, and the study mode.
class StudySession extends ChangeNotifier {
  String? courseId;
  final Set<String> excludedFileIds = {};
  StudyMode mode = StudyMode.explain;

  void selectCourse(String id) {
    courseId = id;
    notifyListeners();
  }

  void toggleFile(String fileId) {
    excludedFileIds.contains(fileId)
        ? excludedFileIds.remove(fileId)
        : excludedFileIds.add(fileId);
    notifyListeners();
  }

  void setMode(StudyMode m) {
    mode = m;
    notifyListeners();
  }

  Set<String> includedFileIds(Course course) => {
        for (final f in course.readyFiles)
          if (!excludedFileIds.contains(f.id)) f.id,
      };
}

class AppServices {
  AppServices._({
    required this.auth,
    required this.lms,
    required this.budget,
    required this.scheduler,
    required this.cache,
    required this.providers,
    required this.courses,
    required this.ingestion,
    required this.tutor,
    required this.animations,
    required this.session,
    required this.preferences,
  });

  /// Everything wired to local mocks. Swap each for its Firebase / Canvas /
  /// Gemini adapter without touching the UI.
  factory AppServices.demo() {
    final store = MemoryStore(); // -> Firebase Realtime Database
    final llm = MockLlm(); // -> Gemini
    final lms = MockCanvas(); // -> Canvas REST via proxy
    final budget = BudgetController();
    final scheduler = RequestScheduler(budget: budget);
    final cache = GenerationCache(store);
    final providers = ProviderRegistry(budget: budget, hosted: llm, byok: (_, _) => llm);
    final courses = CourseRepository(lms);
    return AppServices._(
      auth: MockAuth(), // -> Firebase Auth
      lms: lms,
      budget: budget,
      scheduler: scheduler,
      cache: cache,
      providers: providers,
      courses: courses,
      ingestion: IngestionService(
        lms: lms,
        providers: providers,
        scheduler: scheduler,
        cache: cache,
        courses: courses,
        budget: budget,
      ),
      tutor: TutorService(providers: providers, scheduler: scheduler),
      animations: AnimationService(
        providers: providers,
        scheduler: scheduler,
        cache: cache,
        budget: budget,
      ),
      session: StudySession(),
      preferences: AppPreferences(),
    );
  }

  final AuthService auth;
  final LmsProvider lms;
  final BudgetController budget;
  final RequestScheduler scheduler;
  final GenerationCache cache;
  final ProviderRegistry providers;
  final CourseRepository courses;
  final IngestionService ingestion;
  final TutorService tutor;
  final AnimationService animations;
  final StudySession session;
  final AppPreferences preferences;
}

/// Makes [AppServices] available to the widget tree: `Services.of(context)`.
class Services extends InheritedWidget {
  const Services({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Services>()!.services;

  @override
  bool updateShouldNotify(Services oldWidget) => false;
}
