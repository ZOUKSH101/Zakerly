import 'package:flutter/foundation.dart';

import 'budget.dart';
import 'services.dart';

class ProviderInfo {
  const ProviderInfo({
    required this.id,
    required this.name,
    required this.model,
    required this.available,
  });
  final String id, name, model;
  final bool available;
}

const providerCatalog = [
  ProviderInfo(id: 'gemini', name: 'Google Gemini', model: 'gemini-flash-latest', available: true),
  ProviderInfo(id: 'openai', name: 'OpenAI', model: 'Coming soon', available: false),
  ProviderInfo(id: 'anthropic', name: 'Anthropic Claude', model: 'Coming soon', available: false),
];

/// Bring-your-own-key registry. Keys live in memory on this device and are
/// sent only to their provider; they are never written to the shared database.
class ProviderRegistry extends ChangeNotifier {
  ProviderRegistry({
    required this.budget,
    required this.hosted,
    required this.byok,
  });

  final BudgetController budget;

  /// Zakerly's own key, metered against the plan.
  final LlmProvider hosted;

  /// Builds a client for a student-supplied key.
  final LlmProvider Function(String providerId, String apiKey) byok;

  final _keys = <String, String>{};
  String _activeId = 'gemini';

  String get activeId => _activeId;
  ProviderInfo get active => providerCatalog.firstWhere((p) => p.id == _activeId);
  bool hasKey(String id) => _keys.containsKey(id);

  String maskedKey(String id) {
    final k = _keys[id];
    if (k == null) return '';
    return k.length <= 4 ? '••••' : '••••${k.substring(k.length - 4)}';
  }

  void saveKey(String id, String key) {
    _keys[id] = key.trim();
    notifyListeners();
  }

  void removeKey(String id) {
    _keys.remove(id);
    if (id == _activeId && budget.useOwnKey) budget.setUseOwnKey(false);
    notifyListeners();
  }

  void setActive(String id) {
    _activeId = id;
    if (!hasKey(id) && budget.useOwnKey) budget.setUseOwnKey(false);
    notifyListeners();
  }

  LlmProvider get current => budget.useOwnKey && hasKey(_activeId)
      ? byok(_activeId, _keys[_activeId]!)
      : hosted;
}
