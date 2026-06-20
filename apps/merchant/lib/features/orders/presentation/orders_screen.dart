import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../../core/settings/providers.dart';
import '../application/providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openOrders = ref.watch(openOrdersProvider);
    final tables = ref.watch(tablesProvider).value ?? const [];
    final tableLabels = {for (final t in tables) t.id: t.label};

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ordersTitle)),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'dineIn',
            onPressed: () => _newDineIn(context, ref),
            icon: const Icon(Icons.table_restaurant),
            label: Text(context.l10n.orderDineIn),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'takeout',
            onPressed: () => _newOrder(context, ref, domain.OrderType.takeout),
            icon: const Icon(Icons.takeout_dining),
            label: Text(context.l10n.orderTakeout),
          ),
        ],
      ),
      body: openOrders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(context.l10n.ordersLoadFailed('$e'))),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(child: Text(context.l10n.ordersEmpty));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 120,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              final title = switch (order.type) {
                domain.OrderType.dineIn => context.l10n.orderTableLabel(
                  tableLabels[order.tableId] ?? '?',
                ),
                domain.OrderType.takeout => context.l10n.orderTakeout,
                domain.OrderType.online => context.l10n.orderOnline,
              };
              return Card(
                child: InkWell(
                  onTap: () => context.go('/orders/${order.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          order.total.format(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          TimeOfDay.fromDateTime(
                            order.createdAt,
                          ).format(context),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _newOrder(
    BuildContext context,
    WidgetRef ref,
    domain.OrderType type, {
    String? tableId,
  }) async {
    final repo = ref.read(orderRepositoryProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final id = await repo.createOrder(
      type: type,
      taxRateBp: settings.taxRateBp,
      serviceFeeBp: settings.serviceFeeBp,
      tableId: tableId,
    );
    if (context.mounted) context.go('/orders/$id');
  }

  Future<void> _newDineIn(BuildContext context, WidgetRef ref) async {
    final tables = (ref.read(tablesProvider).value ?? const [])
        .where((t) => t.isActive)
        .toList();
    if (tables.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.noTablesYet)));
      return;
    }
    final picked = await showDialog<domain.DiningTable>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.pickTable),
        children: [
          for (final t in tables)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Text(context.l10n.orderTableLabel(t.label)),
            ),
        ],
      ),
    );
    if (picked != null && context.mounted) {
      await _newOrder(
        context,
        ref,
        domain.OrderType.dineIn,
        tableId: picked.id,
      );
    }
  }
}
