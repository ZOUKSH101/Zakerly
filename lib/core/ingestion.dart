import 'budget.dart';
import 'cache.dart';
import 'courses.dart';
import 'models.dart';
import 'prompts.dart';
import 'providers.dart';
import 'scheduler.dart';
import 'services.dart';
import 'util.dart';

/// Turns raw LMS files into indexed chunks + summaries, once, in the
/// background lane. Summaries are cached by content hash, so a file shared by
/// a whole class is only processed once.
class IngestionService {
  IngestionService({
    required this.lms,
    required this.providers,
    required this.scheduler,
    required this.cache,
    required this.courses,
    required this.budget,
  });

  final LmsProvider lms;
  final ProviderRegistry providers;
  final RequestScheduler scheduler;
  final GenerationCache cache;
  final CourseRepository courses;
  final BudgetController budget;

  /// Free plan limits how many courses can be indexed.
  bool canIndex(Course course) {
    if (course.hasStarted) return true;
    final started = courses.courses.where((c) => c.hasStarted).length;
    return started < budget.plan.maxCourses;
  }

  void indexCourse(Course course) {
    if (!canIndex(course)) return;
    for (final f in course.files) {
      if (f.status == FileStatus.unprocessed || f.status == FileStatus.failed) {
        _indexFile(f);
      }
    }
  }

  void _indexFile(CourseFile file) {
    file
      ..status = FileStatus.queued
      ..error = null;
    courses.touch();

    final job = scheduler.submit(
      label: 'Index ${file.name}',
      lane: JobLane.background,
      estimatedTokens: 1500,
      run: () async {
        file.status = FileStatus.processing;
        courses.touch();

        final text = await lms.fetchFileText(file);
        file.chunks = _chunk(file, text);

        final key = 'summary:v1:${file.id}:${stableHash(text)}';
        final hit = await cache.lookup(key);
        if (hit != null) {
          file
            ..summary = hit.value
            ..status = FileStatus.ready;
          courses.touch();
          return 0;
        }

        final res = await providers.current.generate(LlmRequest(
          purpose: LlmPurpose.summarize,
          system: Prompts.summarizeSystem,
          prompt: Prompts.summarize(file.name, text),
          maxOutputTokens: 600,
        ));
        await cache.save(key, res.text, res.totalTokens);
        file
          ..summary = res.text
          ..status = FileStatus.ready;
        courses.touch();
        return res.totalTokens;
      },
    );

    job.done.catchError((Object e) {
      file
        ..status = FileStatus.failed
        ..error = '$e';
      courses.touch();
    });
  }

  /// Splits on "## " section headings. Real files go through a text extractor
  /// first; the chunk boundaries stay the same idea.
  List<Chunk> _chunk(CourseFile file, String text) {
    final chunks = <Chunk>[];
    for (final part in text.split(RegExp(r'^## ', multiLine: true))) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final nl = trimmed.indexOf('\n');
      chunks.add(Chunk(
        fileId: file.id,
        fileName: file.name,
        heading: nl == -1 ? trimmed : trimmed.substring(0, nl).trim(),
        text: nl == -1 ? '' : trimmed.substring(nl + 1).trim(),
      ));
    }
    return chunks;
  }
}
