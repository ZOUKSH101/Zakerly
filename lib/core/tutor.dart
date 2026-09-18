import 'package:flutter/foundation.dart';

import 'models.dart';
import 'preferences.dart';
import 'prompts.dart';
import 'providers.dart';
import 'retrieval.dart';
import 'scheduler.dart';
import 'services.dart';
import 'util.dart';

/// What a turn will send, shown to the student before they hit send.
class ContextPlan {
  const ContextPlan({
    required this.chunks,
    required this.promptTokens,
    required this.naiveTokens,
  });
  final List<Chunk> chunks;
  final int promptTokens;

  /// Cost of pasting the selected files in full.
  final int naiveTokens;
}

class TutorService extends ChangeNotifier {
  TutorService({required this.providers, required this.scheduler, AppLanguage Function()? language})
      : _language = language ?? (() => AppLanguage.english);

  final ProviderRegistry providers;
  final RequestScheduler scheduler;

  /// The app language, read at ask time so the model answers in it.
  final AppLanguage Function() _language;
  final _threads = <String, List<ChatMessage>>{};

  List<ChatMessage> thread(String courseId) => _threads.putIfAbsent(courseId, () => []);

  /// Forgets every conversation (on sign-out, so the next person on this
  /// device starts clean).
  void clearThreads() {
    _threads.clear();
    notifyListeners();
  }

  // "Sum up the main ideas", "quiz me on this week" and friends name no
  // specific term, so keyword retrieval finds nothing. Those get an overview
  // instead: the opening sections of each selected file.
  static final _broad = RegExp(
    r'summ|sum up|main idea|key idea|overview|hardest|difficult|review|recap|quiz|test me|this week|'
    r'everything|what is this course|لخص|تلخيص|أهم|أصعب|راجع|امتحن|اختبر',
    caseSensitive: false,
  );

  /// Arabic short vowels and shadda ("لخّصلي") would hide the stems above.
  static final _harakat = RegExp('[ً-ْ]');

  static bool _isBroadRequest(String q) => _broad.hasMatch(q.replaceAll(_harakat, ''));

  static List<Chunk> _overview(List<CourseFile> files) => [
        for (var i = 0; i < 2; i++)
          for (final f in files)
            if (f.chunks.length > i) f.chunks[i],
      ].take(6).toList();

  ContextPlan plan(Course course, Set<String> fileIds, String question, StudyMode mode) {
    final files = course.readyFiles.where((f) => fileIds.contains(f.id)).toList();
    var chunks = retrieve(question, files.expand((f) => f.chunks));
    if (chunks.isEmpty && _isBroadRequest(question)) chunks = _overview(files);
    final history = _historyTail(course.id);
    final prompt = Prompts.tutor(context: chunks, history: history, question: question);
    final system = Prompts.tutorSystem(course, mode, language: _language());
    return ContextPlan(
      chunks: chunks,
      promptTokens: estimateTokens(system) + estimateTokens(prompt),
      naiveTokens: files.fold(0, (s, f) => s + f.sourceTokens) + estimateTokens(question),
    );
  }

  Future<void> ask(Course course, Set<String> fileIds, String question, StudyMode mode) async {
    final plan = this.plan(course, fileIds, question, mode);
    final history = _historyTail(course.id);
    final thread = this.thread(course.id);
    final reply = ChatMessage(author: Author.tutor, text: '', pending: true);
    thread
      ..add(ChatMessage(author: Author.student, text: question))
      ..add(reply);
    notifyListeners();

    if (plan.chunks.isEmpty) {
      // Nothing relevant in the selected material: answer locally, spend nothing.
      reply
        ..text = 'I couldn\'t find that in your files. '
            'Try words from your slides, or turn on more files in Status.'
        ..notice = TutorNotice.notFound
        ..pending = false;
      notifyListeners();
      return;
    }

    final language = _language();
    late LlmResponse res;
    final job = scheduler.submit(
      label: 'Answer · ${course.code}',
      kind: JobKind.answer,
      subject: course.code,
      lane: JobLane.interactive,
      estimatedTokens: plan.promptTokens + 800,
      run: () async {
        res = await providers.current.generate(LlmRequest(
          purpose: LlmPurpose.tutor,
          system: Prompts.tutorSystem(course, mode, language: language),
          prompt: Prompts.tutor(context: plan.chunks, history: history, question: question),
          maxOutputTokens: 800,
        ));
        return res.totalTokens;
      },
    );

    try {
      await job.done;
      final seen = <String>{};
      reply
        ..text = res.text
        ..tokens = res.totalTokens
        ..naiveTokens = plan.naiveTokens
        ..citations = [
          for (final c in plan.chunks)
            if (seen.add('${c.fileName}|${c.heading}')) Citation(c.fileName, c.heading),
        ];
    } catch (e) {
      reply
        ..failed = true
        ..notice = e is OutOfBudgetError ? TutorNotice.outOfBudget : TutorNotice.failed
        ..text = e is OutOfBudgetError ? e.message : 'I couldn\'t answer that just now. Try sending it again.';
    } finally {
      reply.pending = false;
      notifyListeners();
    }
  }

  List<ChatMessage> _historyTail(String courseId) {
    final done = thread(courseId).where((m) => !m.pending && !m.failed).toList();
    return done.length <= 4 ? done : done.sublist(done.length - 4);
  }
}
