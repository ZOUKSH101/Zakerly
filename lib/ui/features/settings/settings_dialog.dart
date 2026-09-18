// SettingsDialog: a two-pane layout. A short list on the left (General,
// Plan, Model keys, Account) and the chosen section on the right, so every
// section fits on one screen without scrolling at desktop sizes. When the
// dialog is narrow, the list turns into a row of tabs above the content, and
// the content scrolls on its own if a small window can't fit it.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_services.dart';
import '../../../core/budget.dart';
import '../../../core/preferences.dart';
import '../../../core/providers.dart';
import '../../../core/util.dart';
import '../../primitives/primitives.dart';
import '../tutorial/tutorial.dart';

Future<void> showSettingsDialog(BuildContext context) {
  // The workspace's context: the tour must be shown from here, after the
  // dialog has gone, so it can light up the real panels.
  final host = context;
  return showZDialog(
    context,
    builder: (context) {
      final vp = MediaQuery.sizeOf(context);
      final width = math.min(900.0, vp.width - 2 * ZSpace.s16).clamp(0.0, double.infinity);
      final height = math.min(600.0, vp.height - 2 * ZSpace.s16).clamp(0.0, double.infinity);
      return Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: 'Settings',
        child: ZDialogFrame(
          title: 'Settings',
          width: width,
          height: height,
          child: _SettingsBody(host: host),
        ),
      );
    },
  );
}

enum _Section {
  general('General', Icons.tune_rounded),
  plan('Plan', Icons.workspace_premium_outlined),
  keys('Model keys', Icons.key_outlined),
  account('Account', Icons.person_outline_rounded);

  const _Section(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody({required this.host});

  final BuildContext host;

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  static const _capSteps = [100000, 250000, 500000, 1000000, 2000000, 5000000, 10000000];

  /// Below this body width the side list becomes a row of tabs.
  static const _twoPaneWidth = 600.0;

  _Section _section = _Section.general;
  String? _addingId;
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _saveKey(AppServices s, String id) {
    final text = _keyController.text;
    if (text.trim().isEmpty) return;
    s.providers.saveKey(id, text);
    _keyController.clear();
    TextInput.finishAutofillContext(shouldSave: false);
    setState(() => _addingId = null);
  }

  void _cancelAddKey() {
    _keyController.clear();
    TextInput.finishAutofillContext(shouldSave: false);
    setState(() => _addingId = null);
  }

  void _replayTutorial() {
    final host = widget.host;
    Navigator.of(context).pop();
    // Let the dialog and its dimmed backdrop leave before the tour measures
    // the panels underneath.
    Future<void>.delayed(ZMotion.enter, () {
      if (host.mounted) showTutorial(host);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([s.budget, s.providers, s.cache, s.auth.user, s.preferences]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final content = _content(context, s);
            if (constraints.maxWidth < _twoPaneWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final section in _Section.values) ...[
                          _NavItem(
                            section: section,
                            selected: section == _section,
                            compact: true,
                            onTap: () => setState(() => _section = section),
                          ),
                          const SizedBox(width: ZSpace.s4),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: ZSpace.s16),
                  Expanded(child: content),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: ZLayout.sideNavWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final section in _Section.values) ...[
                        _NavItem(
                          section: section,
                          selected: section == _section,
                          onTap: () => setState(() => _section = section),
                        ),
                        const SizedBox(height: ZSpace.s4),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ZSpace.s20),
                  child: Container(width: 1, color: context.z.hairline),
                ),
                Expanded(child: content),
              ],
            );
          },
        );
      },
    );
  }

  Widget _content(BuildContext context, AppServices s) {
    final pane = switch (_section) {
      _Section.general => _generalPane(context, s),
      _Section.plan => _planPane(context, s),
      _Section.keys => _keysPane(context, s),
      _Section.account => _accountPane(context, s),
    };
    return AnimatedSwitcher(
      duration: ZMotion.medium,
      switchInCurve: ZMotion.decel,
      switchOutCurve: ZMotion.exitCurve,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(
        key: ValueKey(_section),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_section.label, style: context.type.titleLarge),
              const SizedBox(height: ZSpace.s20),
              pane,
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: ZSpace.s8),
        child: Text(text, style: context.type.labelLarge),
      );

  Widget _hairline(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.z.hairline);

  // ---- General ---------------------------------------------------------

  Widget _generalPane(BuildContext context, AppServices s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, 'Appearance'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ZSegmented<ThemeMode>(
            segments: const [
              (ThemeMode.system, 'System'),
              (ThemeMode.light, 'Light'),
              (ThemeMode.dark, 'Dark'),
            ],
            selected: s.preferences.themeMode,
            onChanged: s.preferences.setThemeMode,
          ),
        ),
        const SizedBox(height: ZSpace.s24),
        _label(context, 'Language'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ZSegmented<AppLanguage>(
            segments: const [
              (AppLanguage.english, 'English'),
              (AppLanguage.arabic, 'العربية'),
            ],
            selected: s.preferences.language,
            onChanged: s.preferences.setLanguage,
          ),
        ),
        const SizedBox(height: ZSpace.s24),
        _hairline(context),
        const SizedBox(height: ZSpace.s20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tutorial', style: context.type.bodyLarge),
                  Text(
                    'A 30 second tour of the workspace.',
                    style: context.type.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: ZSpace.s12),
            ZButton(
              label: 'Show tutorial again',
              variant: ZButtonVariant.tonal,
              size: ZButtonSize.sm,
              onPressed: _replayTutorial,
            ),
          ],
        ),
      ],
    );
  }

  // ---- Plan --------------------------------------------------------------

  Widget _planPane(BuildContext context, AppServices s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 480;
        final free = _planCard(context, s, PlanTier.free, fill: sideBySide);
        final pro = _planCard(context, s, PlanTier.pro, fill: sideBySide);
        final cards = !sideBySide
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [free, const SizedBox(height: ZLayout.cardGap), pro],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: free),
                    const SizedBox(width: ZLayout.cardGap),
                    Expanded(child: pro),
                  ],
                ),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cards,
            const SizedBox(height: ZSpace.s16),
            Text('This is a demo, so switching plans is free.', style: context.type.bodySmall),
          ],
        );
      },
    );
  }

  /// [fill]: the card is stretched to its neighbour's height, so the button
  /// sits at the bottom edge and both cards line up.
  Widget _planCard(BuildContext context, AppServices s, PlanTier tier, {required bool fill}) {
    final z = context.z;
    final plan = plans[tier]!;
    final isCurrent = s.budget.tier == tier;

    return ZCard(
      selected: isCurrent,
      padding: ZSpace.s20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(plan.name, style: context.type.titleMedium)),
              if (isCurrent) const ZBadge(label: 'Current', tone: ZBadgeTone.accent),
            ],
          ),
          const SizedBox(height: 2),
          Text(plan.price, style: context.type.bodySmall),
          const SizedBox(height: ZSpace.s12),
          for (final perk in plan.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: ZSpace.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_rounded, size: ZIcon.sm, color: z.success),
                  ),
                  const SizedBox(width: ZSpace.s8),
                  Expanded(
                    child: Text(perk, style: context.type.bodySmall?.copyWith(color: z.text)),
                  ),
                ],
              ),
            ),
          if (fill) const Spacer(),
          if (!isCurrent) ...[
            const SizedBox(height: ZSpace.s4),
            ZButton(
              label: 'Switch to ${plan.name}',
              variant: tier == PlanTier.pro ? ZButtonVariant.filled : ZButtonVariant.tonal,
              size: ZButtonSize.sm,
              expand: true,
              onPressed: () => s.budget.setTier(tier),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Model keys (BYOK) -------------------------------------------------

  Widget _keysPane(BuildContext context, AppServices s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Have your own API key? It stays on this device and only goes to that provider.',
          style: context.type.bodyMedium,
        ),
        const SizedBox(height: ZSpace.s12),
        for (final p in providerCatalog) _providerRow(context, s, p),
        const SizedBox(height: ZSpace.s12),
        _hairline(context),
        const SizedBox(height: ZSpace.s16),
        ZSwitchRow(
          title: 'Use my own key',
          subtitle: 'Pay with your key instead of your plan\'s budget',
          value: s.budget.useOwnKey,
          onChanged: s.providers.hasKey(s.providers.activeId) ? s.budget.setUseOwnKey : null,
        ),
        if (s.budget.useOwnKey) ...[
          const SizedBox(height: ZSpace.s16),
          Text(
            'Monthly cap: ${formatTokens(s.budget.ownKeyCap)}',
            style: context.type.bodyLarge,
          ),
          _capSlider(context, s),
        ],
      ],
    );
  }

  Widget _providerRow(BuildContext context, AppServices s, ProviderInfo p) {
    final adding = _addingId == p.id;
    final hasKey = s.providers.hasKey(p.id);

    Widget trailing;
    if (hasKey) {
      final masked = s.providers.maskedKey(p.id);
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '${p.name} key ending ${masked.replaceAll('•', '')}',
            excludeSemantics: true,
            child: Text(masked, style: context.type.bodySmall),
          ),
          const SizedBox(width: ZSpace.s4),
          ZIconButton(
            icon: Icons.delete_outline,
            tooltip: 'Remove ${p.name} key',
            onPressed: () => s.providers.removeKey(p.id),
          ),
        ],
      );
    } else if (!p.available) {
      trailing = const ZBadge(label: 'Soon');
    } else if (adding) {
      trailing = const SizedBox.shrink();
    } else {
      trailing = ZButton(
        label: 'Add key',
        variant: ZButtonVariant.tonal,
        size: ZButtonSize.sm,
        onPressed: () => setState(() {
          _addingId = p.id;
          _keyController.clear();
        }),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ZSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.name, style: context.type.bodyLarge),
                    Text(p.model, style: context.type.bodySmall),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          if (adding) ...[
            const SizedBox(height: ZSpace.s8),
            Row(
              children: [
                Expanded(
                  child: ZTextField(
                    controller: _keyController,
                    hint: 'Paste API key',
                    label: '${p.name} API key',
                    obscure: true,
                    autofocus: true,
                    autofillHints: const <String>[],
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveKey(s, p.id),
                  ),
                ),
                const SizedBox(width: ZSpace.s8),
                ZButton(
                  label: 'Cancel',
                  variant: ZButtonVariant.plain,
                  size: ZButtonSize.sm,
                  onPressed: _cancelAddKey,
                ),
                const SizedBox(width: ZSpace.s4),
                ZButton(
                  label: 'Save',
                  size: ZButtonSize.sm,
                  onPressed: () => _saveKey(s, p.id),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  int _nearestCapIndex(int cap) {
    var best = 0;
    var bestDiff = (cap - _capSteps[0]).abs();
    for (var i = 1; i < _capSteps.length; i++) {
      final diff = (cap - _capSteps[i]).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    return best;
  }

  Widget _capSlider(BuildContext context, AppServices s) {
    final index = _nearestCapIndex(s.budget.ownKeyCap);
    return Semantics(
      label: 'Monthly cap',
      child: Slider(
        value: index.toDouble(),
        min: 0,
        max: (_capSteps.length - 1).toDouble(),
        divisions: _capSteps.length - 1,
        label: formatTokens(_capSteps[index]),
        semanticFormatterCallback: (v) =>
            '${formatTokens(_capSteps[v.round()])} tokens per month',
        onChanged: (v) => s.budget.setOwnKeyCap(_capSteps[v.round()]),
      ),
    );
  }

  // ---- Account -----------------------------------------------------------

  Widget _accountPane(BuildContext context, AppServices s) {
    final z = context.z;
    final user = s.auth.user.value;
    final cache = s.cache;
    final name = user?.name ?? 'Guest';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: z.accentSoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(initial, style: context.type.titleMedium?.copyWith(color: z.accentText)),
            ),
            const SizedBox(width: ZSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: context.type.titleMedium),
                  if ((user?.email ?? '').isNotEmpty)
                    Text(user!.email, style: context.type.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: ZSpace.s12),
            ZButton(
              label: 'Sign out',
              variant: ZButtonVariant.plain,
              size: ZButtonSize.sm,
              onPressed: () {
                Navigator.of(context).pop();
                s.auth.signOut();
              },
            ),
          ],
        ),
        const SizedBox(height: ZSpace.s20),
        _hairline(context),
        const SizedBox(height: ZSpace.s8),
        ZRow(
          leading: Icon(Icons.school_outlined, size: ZIcon.md, color: z.textSecondary),
          title: s.lms.name,
          subtitle: s.lms.host,
          trailing: const ZBadge(label: 'Connected (demo)', tone: ZBadgeTone.success),
        ),
        const SizedBox(height: ZSpace.s16),
        _label(context, 'Shared with your class'),
        ZCard(
          padding: ZSpace.s20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _cacheStat(context, 'Reused', '${cache.hits}'),
                  _cacheStat(context, 'Made new', '${cache.misses}'),
                  _cacheStat(context, 'Reuse rate', '${(cache.hitRate * 100).round()}%'),
                ],
              ),
              const SizedBox(height: ZSpace.s12),
              Text(
                '${formatTokens(cache.tokensSaved)} tokens saved',
                style: context.type.labelLarge?.copyWith(color: z.successText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cacheStat(BuildContext context, String label, String value) {
    final z = context.z;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: context.type.titleLarge),
          Text(label, style: context.type.bodySmall?.copyWith(color: z.textSecondary)),
        ],
      ),
    );
  }
}

/// One entry in the settings list: icon and label, Hibiscus when selected.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final _Section section;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final z = context.z;
    final fg = selected ? z.accentText : z.text;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: section.label,
        child: AnimatedContainer(
          duration: ZMotion.medium,
          curve: ZMotion.standard,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: ZSpace.s12),
          decoration: BoxDecoration(
            color: selected ? z.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(ZRadius.md),
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(section.icon, size: ZIcon.md, color: selected ? z.accentText : z.textSecondary),
              const SizedBox(width: ZSpace.s12),
              Text(
                section.label,
                style: (selected
                        ? ZType.withWeight(context.type.bodyLarge!, FontWeight.w500)
                        : context.type.bodyLarge)
                    ?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
