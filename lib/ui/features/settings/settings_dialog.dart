// SettingsDialog: plan, BYOK model keys and account, three equal columns
// separated by hairlines (stacked on small viewports). No page scroll at the
// >=780x448 breakpoint; scrolls as a single column below it.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_services.dart';
import '../../../core/budget.dart';
import '../../../core/providers.dart';
import '../../../core/util.dart';
import '../../primitives/primitives.dart';
import '../tutorial/tutorial.dart';

Future<void> showSettingsDialog(BuildContext context) {
  return showZDialog(
    context,
    builder: (context) {
      final vp = MediaQuery.sizeOf(context);
      final width = math.min(940.0, vp.width - 2 * ZSpace.s24).clamp(0.0, double.infinity);
      final height = math.min(560.0, vp.height - 2 * ZSpace.s24).clamp(0.0, double.infinity);
      return Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: 'Settings',
        child: ZDialogFrame(
          title: 'Settings',
          subtitle: 'Plan, model keys and account',
          width: width,
          height: height,
          child: const _SettingsBody(),
        ),
      );
    },
  );
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  static const _capSteps = [100000, 250000, 500000, 1000000, 2000000, 5000000, 10000000];
  static const _breakWidth = 780.0;
  static const _breakHeight = 448.0;

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

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([s.budget, s.providers, s.cache, s.auth.user]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < _breakWidth || constraints.maxHeight < _breakHeight;
            if (stacked) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _planColumn(context, s, stacked: true),
                    const SizedBox(height: ZSpace.s16),
                    _rowDivider(context),
                    const SizedBox(height: ZSpace.s16),
                    _keysColumn(context, s),
                    const SizedBox(height: ZSpace.s16),
                    _rowDivider(context),
                    const SizedBox(height: ZSpace.s16),
                    _accountColumn(context, s),
                  ],
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _planColumn(context, s, stacked: false)),
                _columnDivider(context),
                Expanded(child: _keysColumn(context, s)),
                _columnDivider(context),
                Expanded(child: _accountColumn(context, s)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _columnDivider(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZSpace.s16),
        child: Container(width: 1, color: context.z.hairline),
      );

  Widget _rowDivider(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.z.hairline);

  // ---- Column 1: Plan ------------------------------------------------

  Widget _planColumn(BuildContext context, AppServices s, {required bool stacked}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZEyebrow('Plan'),
        const SizedBox(height: ZSpace.s8),
        _planCard(context, s, PlanTier.free),
        const SizedBox(height: ZSpace.s8),
        _planCard(context, s, PlanTier.pro),
        if (stacked) const SizedBox(height: ZSpace.s12) else const Spacer(),
        Text(
          "Payments aren't hooked up in this demo yet.",
          style: context.type.bodySmall,
        ),
      ],
    );
  }

  Widget _planCard(BuildContext context, AppServices s, PlanTier tier) {
    final z = context.z;
    final plan = plans[tier]!;
    final isCurrent = s.budget.tier == tier;

    return ZCard(
      padding: ZSpace.s12,
      selected: isCurrent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name, style: context.type.titleMedium),
              ),
              if (isCurrent) const ZBadge(label: 'Current', tone: ZBadgeTone.accent),
            ],
          ),
          Text(plan.price, style: context.type.bodySmall),
          const SizedBox(height: ZSpace.s8),
          for (final perk in plan.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: ZSpace.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: ZIcon.sm, color: z.success),
                  const SizedBox(width: ZSpace.s4),
                  Expanded(child: Text(perk, style: context.type.bodySmall)),
                ],
              ),
            ),
          if (!isCurrent) ...[
            const SizedBox(height: ZSpace.s4),
            ZButton(
              label: 'Switch to ${plan.name}',
              variant: ZButtonVariant.tonal,
              size: ZButtonSize.sm,
              onPressed: () => s.budget.setTier(tier),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Column 2: Model keys (BYOK) -----------------------------------

  Widget _keysColumn(BuildContext context, AppServices s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZEyebrow('Model keys'),
        const SizedBox(height: ZSpace.s8),
        Text(
          'Bring your own key — it stays on this device and goes straight to the provider.',
          style: context.type.bodySmall,
        ),
        const SizedBox(height: ZSpace.s12),
        for (final p in providerCatalog) _providerRow(context, s, p),
        const SizedBox(height: ZSpace.s8),
        _rowDivider(context),
        const SizedBox(height: ZSpace.s12),
        ZSwitchRow(
          title: 'Use my own key',
          subtitle: 'Spend from your key instead of your plan',
          value: s.budget.useOwnKey,
          onChanged: s.providers.hasKey(s.providers.activeId) ? s.budget.setUseOwnKey : null,
        ),
        if (s.budget.useOwnKey) ...[
          const SizedBox(height: ZSpace.s12),
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
        variant: ZButtonVariant.plain,
        size: ZButtonSize.sm,
        onPressed: () => setState(() {
          _addingId = p.id;
          _keyController.clear();
        }),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ZSpace.s4),
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
      label: 'Monthly token cap',
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

  // ---- Column 3: Account ----------------------------------------------

  Widget _accountColumn(BuildContext context, AppServices s) {
    final z = context.z;
    final user = s.auth.user.value;
    final cache = s.cache;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZEyebrow('Account'),
        const SizedBox(height: ZSpace.s8),
        Text(user?.name ?? '—', style: context.type.titleMedium),
        const SizedBox(height: ZSpace.s4),
        Text(user?.email ?? '', style: context.type.bodySmall),
        const SizedBox(height: ZSpace.s12),
        ZButton(
          label: 'Sign out',
          variant: ZButtonVariant.danger,
          size: ZButtonSize.sm,
          onPressed: () {
            Navigator.of(context).pop();
            s.auth.signOut();
          },
        ),
        const SizedBox(height: ZSpace.s8),
        ZButton(
          label: 'Show tutorial again',
          variant: ZButtonVariant.plain,
          size: ZButtonSize.sm,
          onPressed: () => showTutorial(context),
        ),
        const SizedBox(height: ZSpace.s20),
        ZRow(
          title: s.lms.name,
          subtitle: s.lms.host,
          trailing: const ZBadge(label: 'Connected (demo)', tone: ZBadgeTone.success),
        ),
        const SizedBox(height: ZSpace.s20),
        const ZEyebrow('Shared cache'),
        const SizedBox(height: ZSpace.s8),
        ZCard(
          padding: ZSpace.s12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _cacheStat(context, 'Hits', '${cache.hits}'),
                  _cacheStat(context, 'Misses', '${cache.misses}'),
                  _cacheStat(context, 'Hit rate', '${(cache.hitRate * 100).round()}%'),
                ],
              ),
              const SizedBox(height: ZSpace.s8),
              Text(
                '${formatTokens(cache.tokensSaved)} tokens saved',
                style: context.type.labelLarge?.copyWith(color: z.success),
              ),
              const SizedBox(height: ZSpace.s4),
              Text(
                'Generated once per course, then reused by everyone.',
                style: context.type.bodySmall,
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
          Text(value, style: context.type.titleMedium),
          Text(label, style: context.type.labelSmall?.copyWith(color: z.textSecondary)),
        ],
      ),
    );
  }
}
