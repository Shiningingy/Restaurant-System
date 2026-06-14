import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';

class ModifierGroupsTab extends ConsumerWidget {
  const ModifierGroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(modifierGroupsProvider).value ?? const [];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editGroup(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.modGroup),
      ),
      body: groups.isEmpty
          ? Center(child: Text(context.l10n.modGroupsEmpty))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final g = groups[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ExpansionTile(
                    title: Text(g.name),
                    subtitle: Text(_requirementLabel(context, g)),
                    childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
                    children: [
                      for (final m in g.modifiers)
                        ListTile(
                          dense: true,
                          title: Text(m.name),
                          subtitle: m.priceDelta.isZero
                              ? null
                              : Text(
                                  '${m.priceDelta.isNegative ? '' : '+'}${m.priceDelta.format()}',
                                ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref
                                .read(menuRepositoryProvider)
                                .deleteModifier(m.id),
                          ),
                          onTap: () => _editModifier(context, ref, g.id, m),
                        ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _editModifier(context, ref, g.id, null),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(context.l10n.modModifier),
                          ),
                          TextButton.icon(
                            onPressed: () => _editGroup(context, ref, g),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(context.l10n.modEditGroup),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteGroup(context, ref, g),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text(context.l10n.modDeleteGroup),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _requirementLabel(BuildContext context, domain.ModifierGroup g) {
    if (g.minSelect == 0) {
      return g.maxSelect == 1
          ? context.l10n.modOptionalPickOne
          : context.l10n.modOptionalUpTo(g.maxSelect);
    }
    if (g.minSelect == g.maxSelect) {
      return context.l10n.modRequiredPick(g.minSelect);
    }
    return context.l10n.modRequiredPickRange(g.minSelect, g.maxSelect);
  }

  Future<void> _editGroup(
    BuildContext context,
    WidgetRef ref,
    domain.ModifierGroup? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final min = TextEditingController(text: '${existing?.minSelect ?? 0}');
    final max = TextEditingController(text: '${existing?.maxSelect ?? 1}');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existing == null
              ? context.l10n.modNewGroup
              : context.l10n.modEditGroup,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.modGroupNameLabel,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: min,
                    decoration: InputDecoration(
                      labelText: context.l10n.modMinPicks,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: max,
                    decoration: InputDecoration(
                      labelText: context.l10n.modMaxPicks,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    final minV = int.tryParse(min.text) ?? 0;
    final maxV = int.tryParse(max.text) ?? 1;
    if (saved == true &&
        name.text.trim().isNotEmpty &&
        maxV >= 1 &&
        minV >= 0 &&
        minV <= maxV) {
      await ref
          .read(menuRepositoryProvider)
          .upsertModifierGroup(
            domain.ModifierGroup(
              id: existing?.id ?? domain.newId(),
              name: name.text.trim(),
              minSelect: minV,
              maxSelect: maxV,
            ),
          );
    }
  }

  Future<void> _editModifier(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    domain.Modifier? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final delta = TextEditingController(
      text: existing == null
          ? '0.00'
          : (existing.priceDelta.cents / 100).toStringAsFixed(2),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existing == null
              ? context.l10n.modNewModifier
              : context.l10n.modEditModifier,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(labelText: context.l10n.modName),
            ),
            TextField(
              controller: delta,
              decoration: InputDecoration(
                labelText: context.l10n.modPriceChange,
                prefixText: r'$',
                helperText: context.l10n.modPriceChangeHelper,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    final parsedDelta = domain.Money.tryParse(delta.text);
    if (saved == true && name.text.trim().isNotEmpty && parsedDelta != null) {
      await ref
          .read(menuRepositoryProvider)
          .upsertModifier(
            domain.Modifier(
              id: existing?.id ?? domain.newId(),
              groupId: groupId,
              name: name.text.trim(),
              priceDelta: parsedDelta,
            ),
          );
    }
  }

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    domain.ModifierGroup g,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.modDeleteGroupConfirm(g.name)),
        content: Text(context.l10n.modDeleteGroupBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(menuRepositoryProvider).deleteModifierGroup(g.id);
    }
  }
}
