import 'package:flutter/foundation.dart';

import 'models.dart';
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
  TutorService({required this.providers, required this.scheduler});

  final ProviderRegistry providers;
  final RequestScheduler scheduler;
  final _threads = <String, List<ChatMessage>>{};

  List<ChatMessage> thread(String courseId) => _threads.putIfAbsent(courseId, () => []);

  ContextPlan plan(Course course, Set<String> fileIds, String question, StudyMode mode) {
    final files = course.readyFiles.where((f) => fileIds.contains(f.id)).toList();
    final chunks = retrieve(question, files.expand((f) => f.chunks));
    final history = _historyTail(course.id);
    final prompt = Prompts.tutor(context: chunks, history: history, question: question);
    final system = Prompts.tutorSystem(course, mode);
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
            'Try adding more on the right, or use different words from your slides.'
        ..pending = false;
      notifyListeners();
      return;
    }

    late LlmResponse res;
    final job = scheduler.submit(
      label: 'Tutor · ${course.code}',
      lane: JobLane.interactive,
      estimatedTokens: plan.promptTokens + 800,
      run: () async {
        res = await providers.current.generate(LlmRequest(
          purpose: LlmPurpose.tutor,
          system: Prompts.tutorSystem(course, mode),
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
        ..text = e is StateError ? e.message : 'That request failed. Try again.';
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
