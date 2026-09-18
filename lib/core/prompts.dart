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
      'Inline all CSS and JavaScript inside the document. Do not reference any external '
      'URL, font, image, script or stylesheet, and make no network requests. '
      'Fill the whole frame responsively: html and body at 100% width and height; if you use '
      'an SVG, give it a viewBox, width and height at 100%, and preserveAspectRatio; size all '
      'text with clamp() or vmin units, never a fixed pixel size that stays small in a big frame. '
      'Break the explanation into a sequence of steps. Provide visible controls: a Back button, '
      'a Play/Pause button, a Next button, and a step counter reading "Step X of Y". Show one '
      'short caption per step describing what just happened. Wire the left and right arrow keys '
      'to Back and Next, and Space to Play/Pause. Wait for the student to press Next by default; '
      'only advance automatically while Play is active. '
      'Respect prefers-reduced-motion by removing transitions and jumping straight to each step, '
      'still under the student\'s step control. '
      'Support both light and dark mode with a prefers-color-scheme media query. Use #4C63F5 as '
      'the accent color and a plain system font stack. '
      'Keep the writing calm and plain: short sentences, no buzzwords, and never use an em dash '
      'or en dash character. Every fact and label must come from the provided course context. '
      'Keep the whole document under 30KB.';

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
