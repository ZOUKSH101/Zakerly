/// Rough token estimate (~4 characters per token). Good enough for budgeting
/// and pre-flight estimates; providers report exact counts after each call.
int estimateTokens(String s) => s.isEmpty ? 0 : (s.length / 4).ceil();

String formatTokens(int n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
  }
  if (n >= 1000) {
    final v = n / 1000;
    return '${v.toStringAsFixed(v >= 100 ? 0 : 1)}k';
  }
  return '$n';
}

/// Stable content hash used for cache keys. Arithmetic stays below 2^53 so it
/// produces identical results on the web and native runtimes.
String stableHash(String s) {
  var a = 7, b = 11;
  for (final c in s.codeUnits) {
    a = (a * 31 + c) % 4294967291;
    b = (b * 131 + c) % 4294967279;
  }
  return a.toRadixString(16) + b.toRadixString(16);
}

const _stopWords = {
  'the', 'a', 'an', 'of', 'in', 'on', 'for', 'to', 'and', 'or', 'is', 'are',
  'was', 'what', 'how', 'why', 'does', 'do', 'did', 'explain', 'show', 'me',
  'please', 'visualize', 'animate', 'with', 'about', 'can', 'you', 'i', 'it',
  'this', 'that', 'be', 'by', 'at', 'as', 'from', 'my', 'we', 'your', 'tell',
};

/// Lower-cased content words, with a light plural strip. Keeps Arabic letters.
List<String> contentTerms(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9؀-ۿ\s]'), ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.length > 1 && !_stopWords.contains(w))
    .map((w) => w.length > 3 && w.endsWith('s') && !w.endsWith('ss')
        ? w.substring(0, w.length - 1)
        : w)
    .toList();

/// Normalised concept key, so "Explain binary search trees" and
/// "binary search tree?" hit the same cache entry.
String conceptKey(String s) => contentTerms(s).join('-');

String htmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
