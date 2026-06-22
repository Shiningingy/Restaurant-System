import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../../core/settings/providers.dart';
import '../../customer_display/application/kiosk_bridge.dart';
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
          // Self-order (kiosk) orders are unpaid and customer-placed — show them
          // in their own section, each card carrying its pickup number, so staff
          // can spot and reconcile them at the counter.
          final kiosk = [
            for (final o in orders)
              if (kioskPickupCode(o.note) != null) o,
          ];
          final regular = [
            for (final o in orders)
              if (kioskPickupCode(o.note) == null) o,
          ];

          if (kiosk.isEmpty) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: _ordersGridDelegate,
              itemCount: regular.length,
              itemBuilder: (context, i) =>
                  _orderCard(context, regular[i], tableLabels),
            );
          }

          return CustomScrollView(
            slivers: [
              _sectionHeader(context, context.l10n.ordersSelfOrderSection),
              _ordersSliver(context, kiosk, tableLabels),
              _sectionHeader(context, context.l10n.ordersStaffSection),
              _ordersSliver(context, regular, tableLabels),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          );
        },
      ),
    );
  }

  static const _ordersGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 260,
    mainAxisExtent: 120,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  );

  Widget _sectionHeader(BuildContext context, String label) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
      );

  Widget _ordersSliver(
    BuildContext context,
    List<domain.Order> orders,
    Map<String, String> tableLabels,
  ) => SliverPadding(
    padding: const EdgeInsets.all(16),
    sliver: SliverGrid(
      gridDelegate: _ordersGridDelegate,
      delegate: SliverChildBuilderDelegate(
        (context, i) => _orderCard(context, orders[i], tableLabels),
        childCount: orders.length,
      ),
    ),
  );

  Widget _orderCard(
    BuildContext context,
    domain.Order order,
    Map<String, String> tableLabels,
  ) {
    final theme = Theme.of(context);
    final code = kioskPickupCode(order.note);
    final title = switch (order.type) {
      domain.OrderType.dineIn => context.l10n.orderTableLabel(
        tableLabels[order.tableId] ?? '?',
      ),
      domain.OrderType.takeout => context.l10n.orderTakeout,
      domain.OrderType.online => context.l10n.orderOnline,
    };
    return Card(
      // Self-order cards stand out so staff can reconcile them at the counter.
      color: code != null ? theme.colorScheme.tertiaryContainer : null,
      child: InkWell(
        onTap: () => context.go('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (code != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onTertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(order.total.format(), style: theme.textTheme.titleLarge),
              Text(
                TimeOfDay.fromDateTime(order.createdAt).format(context),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
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
