import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../../core/settings/providers.dart';
import '../../menu/application/providers.dart';

/// Manager screen for the comp (free-item) policy: which items staff may give
/// free on their own, and a per-order amount cap. Anything outside this needs a
/// manager PIN at the till (AppPermission.compOverride). Reached from the Admin
/// tab's "Discounts & comps" tile; the tab itself is already manager-gated.
class CompPolicyScreen extends ConsumerWidget {
  const CompPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final policy = ref.watch(compPolicyProvider);
    final categories = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => c.isActive)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDiscounts)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.compPolicyIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.compAmountCap),
              subtitle: Text(
                policy.amountCap.cents == 0
                    ? l10n.compNoCap
                    : l10n.compCapPerOrder(policy.amountCap.format()),
              ),
              trailing: TextButton(
                onPressed: () => _editCap(context, ref, policy.amountCap),
                child: Text(l10n.compSetCap),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.compAllowedItems,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            l10n.compAllowedItemsBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.compNoMenu, textAlign: TextAlign.center),
            )
          else
            for (final c in categories) _CategoryItems(category: c),
        ],
      ),
    );
  }

  Future<void> _editCap(
    BuildContext context,
    WidgetRef ref,
    domain.Money current,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: current.cents == 0 ? '' : (current.cents / 100).toStringAsFixed(2),
    );
    final cents = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.compCapDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: r'$ ',
            hintText: l10n.compCapHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final dollars = double.tryParse(controller.text.trim()) ?? 0;
              Navigator.pop(context, (dollars * 100).round());
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (cents == null) return;
    await ref
        .read(compPolicyProvider.notifier)
        .setAmountCap(domain.Money(cents < 0 ? 0 : cents));
  }
}

/// One category's active items as comp-allow checkboxes.
class _CategoryItems extends ConsumerWidget {
  final domain.Category category;

  const _CategoryItems({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        (ref.watch(itemsInCategoryProvider(category.id)).value ?? const [])
            .where((i) => i.isActive)
            .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final allowed = ref.watch(compPolicyProvider).allowedItemIds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
          child: Text(
            category.name,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        for (final item in items)
          CheckboxListTile(
            dense: true,
            value: allowed.contains(item.id),
            title: Text(item.name),
            secondary: Text(item.price.format()),
            onChanged: (on) {
              final next = {...allowed};
              if (on ?? false) {
                next.add(item.id);
              } else {
                next.remove(item.id);
              }
              ref.read(compPolicyProvider.notifier).setAllowedItemIds(next);
            },
          ),
      ],
    );
  }
}
