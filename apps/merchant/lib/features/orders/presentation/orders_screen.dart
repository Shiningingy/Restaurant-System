import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../settings/application/providers.dart';
import '../application/providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openOrders = ref.watch(openOrdersProvider);
    final tables = ref.watch(tablesProvider).value ?? const [];
    final tableLabels = {for (final t in tables) t.id: t.label};

    return Scaffold(
      appBar: AppBar(title: const Text('Open Orders')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'dineIn',
            onPressed: () => _newDineIn(context, ref),
            icon: const Icon(Icons.table_restaurant),
            label: const Text('Dine-in'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'takeout',
            onPressed: () => _newOrder(context, ref, domain.OrderType.takeout),
            icon: const Icon(Icons.takeout_dining),
            label: const Text('Takeout'),
          ),
        ],
      ),
      body: openOrders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load orders: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('No open orders - start a dine-in or takeout order.'),
            );
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
                domain.OrderType.dineIn =>
                  'Table ${tableLabels[order.tableId] ?? '?'}',
                domain.OrderType.takeout => 'Takeout',
                domain.OrderType.online => 'Online',
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
    final taxRateBp = ref.read(taxRateBpProvider);
    final id = await repo.createOrder(
      type: type,
      taxRateBp: taxRateBp,
      tableId: tableId,
    );
    if (context.mounted) context.go('/orders/$id');
  }

  Future<void> _newDineIn(BuildContext context, WidgetRef ref) async {
    final tables = (ref.read(tablesProvider).value ?? const [])
        .where((t) => t.isActive)
        .toList();
    if (tables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tables yet - add tables in Settings.'),
        ),
      );
      return;
    }
    final picked = await showDialog<domain.DiningTable>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pick a table'),
        children: [
          for (final t in tables)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Text('Table ${t.label}'),
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
