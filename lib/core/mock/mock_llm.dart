import 'dart:math';

import '../animations.dart';
import '../services.dart';
import '../util.dart';
import 'mock_animations.dart';

/// Stand-in for Gemini. Parses the same prompt markers the real model sees
/// and answers only from the supplied context, so grounding and citations
/// behave like production.
class MockLlm implements LlmProvider {
  final _rng = Random();

  @override
  Future<LlmResponse> generate(LlmRequest r) async {
    await Future<void>.delayed(Duration(milliseconds: 700 + _rng.nextInt(900)));
    final text = switch (r.purpose) {
      LlmPurpose.summarize => _summarize(r.prompt),
      LlmPurpose.tutor => _tutor(r.system, r.prompt),
      LlmPurpose.animation => _animation(r.prompt),
    };
    return LlmResponse(
      text: text,
      inputTokens: estimateTokens(r.system) + estimateTokens(r.prompt),
      outputTokens: estimateTokens(text),
    );
  }

  String _summarize(String prompt) {
    final lines = <String>[];
    for (final m in RegExp(r'^## (.+)\n(.+)$', multiLine: true).allMatches(prompt)) {
      lines.add('- ${m[1]!.trim()}: ${_sentences(m[2]!).first}');
    }
    return lines.join('\n');
  }

  String _tutor(String system, String prompt) {
    final sources = _sources(prompt);
    final question = RegExp(r'QUESTION: (.*)$', dotAll: true).firstMatch(prompt)?[1]?.trim() ?? '';
    final first = sources.first;
    final s1 = _sentences(first.text);

    // The app is in Arabic (Prompts.arabicReplyLine): a short Arabic reply
    // around the English course text, the way a real model would quote it.
    if (system.contains('LANGUAGE: ARABIC')) return _tutorArabic(system, question, sources);

    if (system.contains('MODE: SOCRATIC')) {
      return 'Let\'s work this one out together.\n\n'
          'Your notes on ${first.heading} say: "${s1.first}" [${first.file} · ${first.heading}]\n\n'
          'Using that rule, what do you think happens in the case you asked about ("$question"), and why? '
          'Reply with your reasoning and I\'ll check it.';
    }
    if (system.contains('MODE: QUIZ')) {
      final second = sources.length > 1 ? sources[1] : first;
      return 'Three quick questions from your files:\n\n'
          '1. True or false: ${s1.first}\n'
          '2. In your own words, explain ${first.heading.toLowerCase()}.\n'
          '3. What is the main point of "${second.heading}"?\n\n'
          'Answer in the chat and I\'ll mark them. [${first.file} · ${first.heading}]';
    }

    final b = StringBuffer('${s1.take(2).join(' ')} [${first.file} · ${first.heading}]');
    if (s1.length > 2) b.write('\n\n${s1.skip(2).join(' ')}');
    if (sources.length > 1) {
      final other = sources[1];
      b.write('\n\nRelated: ${_sentences(other.text).first} [${other.file} · ${other.heading}]');
    }
    b.write('\n\nWant to see it move? Tap Animate it.');
    return b.toString();
  }

  String _tutorArabic(
    String system,
    String question,
    List<({String file, String heading, String text})> sources,
  ) {
    final first = sources.first;
    final s1 = _sentences(first.text);
    final cite = '[${first.file} · ${first.heading}]';

    if (system.contains('MODE: SOCRATIC')) {
      return 'يلا نحلّها سوا.\n\n'
          'ملاحظاتك عن ${first.heading} بتقول: "${s1.first}" $cite\n\n'
          'على أساس القاعدة دي، تفتكر إيه اللي بيحصل في اللي سألت عنه ("$question")، وليه؟ '
          'اكتبلي تفكيرك وأنا أراجعه معاك.';
    }
    if (system.contains('MODE: QUIZ')) {
      final second = sources.length > 1 ? sources[1] : first;
      return 'تلات أسئلة سريعة من ملفاتك:\n\n'
          '1. صح ولا غلط: ${s1.first}\n'
          '2. اشرح بأسلوبك: ${first.heading}.\n'
          '3. إيه أهم فكرة في "${second.heading}"؟\n\n'
          'جاوب في الشات وأنا هصحّحهم. $cite';
    }

    final b = StringBuffer('باختصار، ده اللي في ملفاتك: ${s1.take(2).join(' ')} $cite');
    if (sources.length > 1) {
      final other = sources[1];
      b.write('\n\nوكمان: ${_sentences(other.text).first} [${other.file} · ${other.heading}]');
    }
    b.write('\n\nعايز تشوفها بتتحرك؟ دوس "حرّكها".');
    return b.toString();
  }

  String _animation(String prompt) {
    final concept = RegExp(r'CONCEPT: (.*)').firstMatch(prompt)?[1]?.trim() ?? 'Concept';
    final sources = _sources(prompt);
    return switch (matchAnimationTemplate(concept)) {
      AnimationTemplate.tree => bstAnimation(concept),
      AnimationTemplate.growth => growthAnimation(concept),
      AnimationTemplate.keyIdeas => keyPointsAnimation(concept, [
          for (final s in sources) (s.heading, _sentences(s.text).first),
        ]),
    };
  }

  List<({String file, String heading, String text})> _sources(String prompt) => [
        for (final m in RegExp(
          r'\[\[source: (.+?) \| (.+?)\]\]\n([\s\S]*?)(?=\n\[\[source:|\n?<<END CONTEXT>>)',
        ).allMatches(prompt))
          (file: m[1]!, heading: m[2]!, text: m[3]!.trim()),
      ];

  List<String> _sentences(String text) {
    final parts = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? [text] : parts;
  }
}
