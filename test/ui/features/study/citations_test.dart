import 'package:flutter_test/flutter_test.dart';

import 'package:zakerly/core/models.dart';
import 'package:zakerly/ui/features/study/citations.dart';

void main() {
  test('numbers sources in order of first mention and dedupes repeats', () {
    final parsed = parseAnswer(
      'A leaf goes. [Week 3 - Binary Search Trees.pdf · Deleting a key] '
      'Heaps differ. [Week 4 - Heaps.pptx · The heap property]\n\n'
      'Back to trees. [Week 3 - Binary Search Trees.pdf · Deleting a key]',
    );

    expect(parsed.sources.map((c) => c.heading), ['Deleting a key', 'The heap property']);
    final cites = parsed.parts.whereType<AnswerCite>().map((c) => c.number).toList();
    expect(cites, [1, 2, 1]);
    final text = parsed.parts.whereType<AnswerText>().map((t) => t.text).join();
    expect(text, isNot(contains('[')));
    // The space before a marker is eaten so the pill hugs the word.
    expect(text, startsWith('A leaf goes.'));
    expect((parsed.parts.first as AnswerText).text, 'A leaf goes.');
  });

  test('hyphens inside file names are not separators', () {
    final parsed = parseAnswer('x [Week 3 - Trees.pdf · Searching a BST]');
    expect(parsed.sources.single.fileName, 'Week 3 - Trees.pdf');
    expect(parsed.sources.single.heading, 'Searching a BST');
  });

  test('back-to-back repeats of the same source collapse to one pill', () {
    final parsed = parseAnswer('x [a.pdf · One][a.pdf · One]');
    expect(parsed.parts.whereType<AnswerCite>().length, 1);
  });

  test('no inline markers falls back to the retrieved sections, deduplicated', () {
    final parsed = parseAnswer('Plain answer.', fallback: const [
      Citation('a.pdf', 'One'),
      Citation('a.pdf', 'One'),
      Citation('b.pdf', 'Two'),
    ]);
    expect(parsed.sources.length, 2);
    expect(parsed.parts.single, isA<AnswerText>());
  });

  test('stripExtension keeps dotless names and drops the last extension', () {
    expect(stripExtension('Week 3 - Trees.pdf'), 'Week 3 - Trees');
    expect(stripExtension('Syllabus'), 'Syllabus');
  });
}
