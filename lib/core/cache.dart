import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'services.dart';

class CacheHit {
  const CacheHit(this.value, this.tokenCost);
  final String value;

  /// What it cost to generate originally — the saving on every reuse.
  final int tokenCost;
}

/// Cache for generated artefacts (animations, file summaries). Keys are
/// scoped per course, not per student, so the first generation pays and
/// everyone after reuses it.
class GenerationCache extends ChangeNotifier {
  GenerationCache(this._store);

  final KeyValueStore _store;
  int hits = 0, misses = 0, tokensSaved = 0;

  Future<CacheHit?> lookup(String key) async {
    final raw = await _store.get(key);
    if (raw == null) {
      misses++;
      notifyListeners();
      return null;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final hit = CacheHit(json['v'] as String, json['t'] as int);
    hits++;
    tokensSaved += hit.tokenCost;
    notifyListeners();
    return hit;
  }

  Future<void> save(String key, String value, int tokenCost) => _store.put(
        key,
        jsonEncode({'v': value, 't': tokenCost, 'at': DateTime.now().toIso8601String()}),
      );

  double get hitRate => hits + misses == 0 ? 0 : hits / (hits + misses);
}
