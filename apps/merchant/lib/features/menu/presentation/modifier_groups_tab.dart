import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

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
        label: const Text('Group'),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text(
                'Modifier groups (e.g. "Size", "Add-ons") appear here.',
              ),
            )
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
                    subtitle: Text(_requirementLabel(g)),
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
                            label: const Text('Modifier'),
                          ),
                          TextButton.icon(
                            onPressed: () => _editGroup(context, ref, g),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit group'),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteGroup(context, ref, g),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete group'),
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

  String _requirementLabel(domain.ModifierGroup g) {
    if (g.minSelect == 0) {
      return g.maxSelect == 1
          ? 'Optional, pick one'
          : 'Optional, up to ${g.maxSelect}';
    }
    if (g.minSelect == g.maxSelect) return 'Required, pick ${g.minSelect}';
    return 'Required, pick ${g.minSelect}-${g.maxSelect}';
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
        title: Text(existing == null ? 'New modifier group' : 'Edit group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name (e.g. Size, Add-ons)',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: min,
                    decoration: const InputDecoration(labelText: 'Min picks'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: max,
                    decoration: const InputDecoration(labelText: 'Max picks'),
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
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
        title: Text(existing == null ? 'New modifier' : 'Edit modifier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: delta,
              decoration: const InputDecoration(
                labelText: 'Price change',
                prefixText: r'$',
                helperText: 'Can be negative, e.g. -0.50',
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
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
        title: Text('Delete "${g.name}"?'),
        content: const Text(
          'Items lose this group. Past orders are unaffected (they keep snapshots).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(menuRepositoryProvider).deleteModifierGroup(g.id);
    }
  }
}
