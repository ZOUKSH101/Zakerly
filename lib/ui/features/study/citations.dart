// Turns a tutor answer's inline "[file · section]" markers (the format the
// tutor prompt asks for, see core/prompts.dart) into numbered references
// that match a deduplicated source list. Pure, so it is easy to test.
import 'package:zakerly/core/models.dart';

/// One run of an answer: plain text, or a reference to [ParsedAnswer.sources]
/// by 1-based number.
sealed class AnswerPart {
  const AnswerPart();
}

class AnswerText extends AnswerPart {
  const AnswerText(this.text);
  final String text;
}

class AnswerCite extends AnswerPart {
  const AnswerCite(this.number);

  /// 1-based index into [ParsedAnswer.sources].
  final int number;
}

class ParsedAnswer {
  const ParsedAnswer(this.parts, this.sources);
  final List<AnswerPart> parts;

  /// Each source once, numbered in order of first mention.
  final List<Citation> sources;
}

/// "[Week 3 - Binary Search Trees.pdf · Deleting a key]". The separator is a
/// middle dot (or a pipe, which models sometimes use). Hyphens are not
/// separators because file names contain them. Leading spaces are eaten so
/// the pill sits right after the word it supports.
final _marker = RegExp(r'[ \t]*\[([^\[\]\n]+?)\s+[·|]\s+([^\[\]\n]+?)\]');

String _key(String file, String heading) => '${file.trim().toLowerCase()}|${heading.trim().toLowerCase()}';

/// Splits [text] into text and numbered citation parts. When the answer has
/// no inline markers, [fallback] (the retrieved sections) becomes the source
/// list so the student still sees where it came from.
ParsedAnswer parseAnswer(String text, {List<Citation> fallback = const []}) {
  final parts = <AnswerPart>[];
  final sources = <Citation>[];
  final numbers = <String, int>{};

  var cursor = 0;
  for (final m in _marker.allMatches(text)) {
    if (m.start > cursor) parts.add(AnswerText(text.substring(cursor, m.start)));
    final file = m[1]!.trim();
    final heading = m[2]!.trim();
    final key = _key(file, heading);
    final n = numbers.putIfAbsent(key, () {
      sources.add(Citation(file, heading));
      return sources.length;
    });
    // The same source twice in a row adds nothing.
    final last = parts.isEmpty ? null : parts.last;
    if (!(last is AnswerCite && last.number == n)) parts.add(AnswerCite(n));
    cursor = m.end;
  }
  if (cursor < text.length) parts.add(AnswerText(text.substring(cursor)));

  if (sources.isEmpty) {
    final seen = <String>{};
    for (final c in fallback) {
      if (seen.add(_key(c.fileName, c.heading))) sources.add(c);
    }
  }
  return ParsedAnswer(parts, sources);
}

/// "Week 3 - Binary Search Trees" from "Week 3 - Binary Search Trees.pdf".
String stripExtension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot <= 0 ? fileName : fileName.substring(0, dot);
}
