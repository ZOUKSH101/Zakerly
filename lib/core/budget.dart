import 'dart:math';

import 'package:flutter/foundation.dart';

enum PlanTier { free, pro }

class Plan {
  const Plan({
    required this.name,
    required this.price,
    required this.monthlyTokens,
    required this.maxCourses,
    required this.animationsPerDay,
    required this.priorityProcessing,
    required this.perks,
  });

  final String name, price;
  final int monthlyTokens, maxCourses, animationsPerDay;

  /// Pro can push background jobs ahead of the off-peak window.
  final bool priorityProcessing;
  final List<String> perks;
}

const plans = {
  PlanTier.free: Plan(
    name: 'Free',
    price: 'EGP 0',
    monthlyTokens: 250000,
    maxCourses: 2,
    animationsPerDay: 5,
    priorityProcessing: false,
    perks: ['2 Canvas courses', '250k tokens a month', '5 new animations a day', 'Processing when it\'s quiet'],
  ),
  PlanTier.pro: Plan(
    name: 'Pro',
    price: 'Price coming soon',
    monthlyTokens: 3000000,
    maxCourses: 50,
    animationsPerDay: 100,
    priorityProcessing: true,
    perks: ['All your courses', '3M tokens a month', '100 new animations a day', 'Faster processing'],
  ),
};

class UsageEntry {
  UsageEntry(this.label, this.tokens, this.ownKey) : at = DateTime.now();
  final String label;
  final int tokens;
  final bool ownKey;
  final DateTime at;
}

/// Tracks spend against whichever budget is active: the plan's hosted
/// allowance, or the cap the student set on their own API key (BYOK).
class BudgetController extends ChangeNotifier {
  PlanTier _tier = PlanTier.free;
  bool _useOwnKey = false;
  int _ownKeyCap = 1000000;
  int _hostedUsed = 0, _ownUsed = 0, _session = 0, _animationsToday = 0;
  final List<UsageEntry> history = [];

  PlanTier get tier => _tier;
  Plan get plan => plans[_tier]!;
  bool get useOwnKey => _useOwnKey;
  int get ownKeyCap => _ownKeyCap;

  int get limit => _useOwnKey ? _ownKeyCap : plan.monthlyTokens;
  int get used => _useOwnKey ? _ownUsed : _hostedUsed;
  int get remaining => max(0, limit - used);
  double get fraction => limit == 0 ? 1 : (used / limit).clamp(0.0, 1.0);
  int get sessionUsed => _session;
  int get animationsToday => _animationsToday;
  bool get canGenerateAnimation => _animationsToday < plan.animationsPerDay;
  String get sourceLabel => _useOwnKey ? 'Your API key' : 'Zakerly ${plan.name}';

  bool canSpend(int tokens) => used + tokens <= limit;

  void record(String label, int tokens) {
    if (tokens <= 0) return;
    if (_useOwnKey) {
      _ownUsed += tokens;
    } else {
      _hostedUsed += tokens;
    }
    _session += tokens;
    history.insert(0, UsageEntry(label, tokens, _useOwnKey));
    if (history.length > 50) history.removeLast();
    notifyListeners();
  }

  void countAnimation() {
    _animationsToday++;
    notifyListeners();
  }

  void setTier(PlanTier t) {
    _tier = t;
    notifyListeners();
  }

  void setUseOwnKey(bool v) {
    _useOwnKey = v;
    notifyListeners();
  }

  void setOwnKeyCap(int v) {
    _ownKeyCap = v;
    notifyListeners();
  }
}
