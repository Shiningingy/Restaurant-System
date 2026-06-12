import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../application/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxRateBp = ref.watch(taxRateBpProvider);
    final tables = ref.watch(tablesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tax', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            title: const Text('Sales tax rate'),
            subtitle: const Text(
              'Applied to new orders; existing orders keep their rate.',
            ),
            trailing: Text(
              '${(taxRateBp / 100).toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => _editTaxRate(context, ref, taxRateBp),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tables', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _editTable(context, ref, null),
                icon: const Icon(Icons.add),
                label: const Text('Table'),
              ),
            ],
          ),
          if (tables.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add tables to enable dine-in orders.'),
            ),
          for (final t in tables)
            ListTile(
              leading: const Icon(Icons.table_restaurant_outlined),
              title: Text('Table ${t.label}'),
              subtitle: t.isActive ? null : const Text('Inactive'),
              onTap: () => _editTable(context, ref, t),
            ),
        ],
      ),
    );
  }

  Future<void> _editTaxRate(
    BuildContext context,
    WidgetRef ref,
    int currentBp,
  ) async {
    final controller = TextEditingController(
      text: (currentBp / 100).toStringAsFixed(2),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sales tax rate'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(suffixText: '%', labelText: 'Rate'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    final percent = double.tryParse(controller.text);
    if (saved == true && percent != null && percent >= 0 && percent < 100) {
      await ref.read(taxRateBpProvider.notifier).setBp((percent * 100).round());
    }
  }

  Future<void> _editTable(
    BuildContext context,
    WidgetRef ref,
    domain.DiningTable? existing,
  ) async {
    final controller = TextEditingController(text: existing?.label ?? '');
    var isActive = existing?.isActive ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'New table' : 'Edit table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Label (e.g. 1, 2, Patio A)',
                ),
              ),
              if (existing != null)
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
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
      ),
    );
    if (saved == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(tablesRepositoryProvider)
          .upsertTable(
            domain.DiningTable(
              id: existing?.id ?? domain.newId(),
              label: controller.text.trim(),
              isActive: isActive,
            ),
          );
    }
  }
}
