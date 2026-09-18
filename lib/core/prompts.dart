import 'animations.dart';
import 'models.dart';
import 'preferences.dart';

/// Prompt templates. These are written for the real model; the mock parses
/// the same markers so the demo exercises the production prompt shape.
class Prompts {
  static const summarizeSystem =
      'You index university course material for a study assistant. '
      'For each section of the document, write one line: "- <section>: <the key idea in one sentence>". '
      'Do not add facts that are not in the document.';

  static String summarize(String fileName, String text) =>
      'DOCUMENT: $fileName\n<<DOCUMENT>>\n$text\n<<END DOCUMENT>>';

  /// Marker line the mock model looks for; the real model just follows it.
  static const arabicReplyLine =
      'LANGUAGE: ARABIC. The student has the app in Arabic, so always reply in Arabic: '
      'friendly, Egyptian-leaning Modern Standard Arabic, the way a senior student talks. '
      'Keep English course terms, file names and section names in English, use Western '
      'digits (1, 2, 3), and keep the [file · section] citations exactly as written.';

  static String tutorSystem(Course course, StudyMode mode, {AppLanguage language = AppLanguage.english}) {
    final base = 'You are Zakerly, a tutor for ${course.code} ${course.name}. '
        'Answer ONLY from the course context provided. If the context does not '
        'contain the answer, say so and name the material the student should check. '
        'Cite sources inline as [file · section]. Reply in the language the student '
        'writes in (Arabic or English). Keep answers short and concrete.';
    final lang = language == AppLanguage.arabic ? '\n$arabicReplyLine' : '';
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
    return '$base\n$style$lang';
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

  /// The animation system prompt for the app's [language] and [theme]: the
  /// document must use the app's words and direction and the app's colours
  /// (not the OS colour scheme), and speak the [AnimationMessages] protocol.
  static String animationSystemFor({
    AppLanguage language = AppLanguage.english,
    AnimationTheme theme = AnimationTheme.light,
  }) {
    final copy = AnimationCopy.of(language);
    final palette = AnimationPalette.of(theme);
    final arabic = language == AppLanguage.arabic;
    final lang = arabic
        ? 'LANGUAGE: ARABIC. Set <html lang="ar" dir="rtl">. Write the title, captions and all '
            'labels in friendly Egyptian-leaning Modern Standard Arabic; keep English course terms '
            'in English and use Western digits. In right-to-left, the Left arrow key goes to the '
            'next step and the Right arrow key goes back. '
        : 'LANGUAGE: ENGLISH. Set <html lang="en" dir="ltr">. ';
    final controls = 'Label the controls exactly "${copy.back}", "${copy.play}" (and '
        '"${copy.pause}" while playing) and "${copy.next}", and write the counter as '
        '"${copy.stepTemplate.replaceAll('{i}', 'X').replaceAll('{n}', 'Y')}". ';
    final colors = 'THEME: ${theme.name.toUpperCase()}. Use exactly this palette and do NOT '
        'use a prefers-color-scheme media query: ${palette.describe}. ';
    const protocol = 'Listen for window "message" events: the string '
        '"${AnimationMessages.back}" goes back one step, "${AnimationMessages.next}" goes '
        'forward one step, "${AnimationMessages.toggle}" toggles Play/Pause. When playback '
        'starts or stops, call parent.postMessage("${AnimationMessages.playing}", "*") or '
        'parent.postMessage("${AnimationMessages.paused}", "*"). When Escape is pressed, call '
        'parent.postMessage("${AnimationMessages.escape}", "*"). ';
    return '$_animationBase$lang$controls$colors$protocol$_animationTail';
  }

  static const _animationBase =
      'You create short educational animations as ONE self-contained HTML document. '
      'Output only the document, starting with <!doctype html>. '
      'Inline all CSS and JavaScript inside the document. Do not reference any external '
      'URL, font, image, script or stylesheet, and make no network requests. '
      'Fill the whole frame responsively: html and body at 100% width and height; if you use '
      'an SVG, give it a viewBox, width and height at 100%, and preserveAspectRatio; size all '
      'text with clamp() or vmin units, never a fixed pixel size that stays small in a big frame. '
      'Break the explanation into a sequence of steps. Provide visible controls: a Back button, '
      'a Play/Pause button, a Next button, and a step counter. Show one '
      'short caption per step describing what just happened. Wire the left and right arrow keys '
      'to Back and Next, and Space to Play/Pause. Wait for the student to press Next by default; '
      'only advance automatically while Play is active. '
      'Respect prefers-reduced-motion by removing transitions and jumping straight to each step, '
      'still under the student\'s step control. Use a plain system font stack. ';

  static const _animationTail =
      'Keep the writing calm and plain: short sentences, no buzzwords, and never use an em dash '
      'or en dash character. Every fact and label must come from the provided course context. '
      'Keep the whole document under 30KB.';

  static String animation(
    String concept,
    List<Chunk> context, {
    AppLanguage language = AppLanguage.english,
    AnimationTheme theme = AnimationTheme.light,
  }) {
    // The LANGUAGE/THEME lines repeat the system prompt's choice so the mock
    // model (which only parses the prompt) draws the same look.
    final b = StringBuffer('LANGUAGE: ${language.code}\nTHEME: ${theme.name}\n'
        'CONCEPT: $concept\n<<CONTEXT>>\n');
    for (final c in context) {
      b.writeln('[[source: ${c.fileName} | ${c.heading}]]');
      b.writeln(c.text);
    }
    b.write('<<END CONTEXT>>');
    return b.toString();
  }
}
