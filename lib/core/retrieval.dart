import 'dart:math';

import 'models.dart';
import 'util.dart';

/// Picks the few sections relevant to [query] instead of sending whole files.
/// TF-IDF with a heading bonus: small, predictable, and runs in the browser.
/// An embedding index can replace it behind the same signature.
List<Chunk> retrieve(
  String query,
  Iterable<Chunk> chunks, {
  int budgetTokens = 1800,
  int maxChunks = 4,
}) {
  final q = contentTerms(query).toSet();
  final all = chunks.toList();
  if (q.isEmpty || all.isEmpty) return const [];

  final termsPerChunk = [
    for (final c in all) contentTerms('${c.heading} ${c.text}'),
  ];
  final df = <String, int>{};
  for (final terms in termsPerChunk) {
    for (final t in terms.toSet()) {
      df[t] = (df[t] ?? 0) + 1;
    }
  }

  final scored = <(Chunk, double)>[];
  for (var i = 0; i < all.length; i++) {
    var score = 0.0;
    for (final t in termsPerChunk[i]) {
      if (q.contains(t)) score += log((all.length + 1) / df[t]!);
    }
    for (final t in contentTerms(all[i].heading)) {
      if (q.contains(t)) score += 1.5;
    }
    if (score > 0) scored.add((all[i], score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));

  final picked = <Chunk>[];
  var used = 0;
  for (final (chunk, _) in scored) {
    if (picked.length >= maxChunks) break;
    if (used + chunk.tokens > budgetTokens && picked.isNotEmpty) continue;
    picked.add(chunk);
    used += chunk.tokens;
  }
  return picked;
}
