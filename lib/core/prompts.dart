import 'models.dart';

/// Prompt templates. These are written for the real model; the mock parses
/// the same markers so the demo exercises the production prompt shape.
class Prompts {
  static const summarizeSystem =
      'You index university course material for a study assistant. '
      'For each section of the document, write one line: "- <section>: <the key idea in one sentence>". '
      'Do not add facts that are not in the document.';

  static String summarize(String fileName, String text) =>
      'DOCUMENT: $fileName\n<<DOCUMENT>>\n$text\n<<END DOCUMENT>>';

  static String tutorSystem(Course course, StudyMode mode) {
    final base = 'You are Zakerly, a tutor for ${course.code} ${course.name}. '
        'Answer ONLY from the course context provided. If the context does not '
        'contain the answer, say so and name the material the student should check. '
        'Cite sources inline as [file · section]. Reply in the language the student '
        'writes in (Arabic or English). Keep answers short and concrete.';
    final style = switch (mode) {
      StudyMode.explain =>
        'MODE: EXPLAIN. Explain step by step, then give one worked example.',
      StudyMode.socratic =>
        'MODE: SOCRATIC. Do not give the answer. Ask one guiding question at a time '
            'and build on the student\'s reasoning.',
      StudyMode.quiz =>
        'MODE: QUIZ. Write three short questions that test the concept, mixing '
            'true/false and free-text. Do not reveal answers until the student replies.',
    };
    return '$base\n$style';
  }

  static String tutor({
    required List<Chunk> context,
    required List<ChatMessage> history,
    required String question,
  }) {
    final b = StringBuffer('<<CONTEXT>>\n');
    for (final c in context) {
      b.writeln('[[source: ${c.fileName} | ${c.heading}]]');
      b.writeln(c.text);
    }
    b.writeln('<<END CONTEXT>>');
    if (history.isNotEmpty) {
      b.writeln('<<HISTORY>>');
      for (final m in history) {
        b.writeln('${m.author == Author.student ? 'STUDENT' : 'TUTOR'}: ${m.text}');
      }
      b.writeln('<<END HISTORY>>');
    }
    b.write('QUESTION: $question');
    return b.toString();
  }

  static const animationSystem =
      'You create short educational animations as ONE self-contained HTML document. '
      'Output only the document, starting with <!doctype html>. '
      'Inline all CSS and JavaScript; no external URLs, fonts, images or network requests. '
      'Fill a 16:9 frame and scale to the container. Loop automatically every 6-12 seconds. '
      'Dark background, high-contrast labels, at most six words per label. '
      'Respect prefers-reduced-motion by showing a static final frame. '
      'Every label must come from the provided course context. Keep it under 30KB.';

  static String animation(String concept, List<Chunk> context) {
    final b = StringBuffer('CONCEPT: $concept\n<<CONTEXT>>\n');
    for (final c in context) {
      b.writeln('[[source: ${c.fileName} | ${c.heading}]]');
      b.writeln(c.text);
    }
    b.write('<<END CONTEXT>>');
    return b.toString();
  }
}
