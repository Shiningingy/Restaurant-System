import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

import '../../../core/l10n_ext.dart';
import '../../storefront/application/providers.dart';
import '../../storefront/presentation/status_screen.dart';
import '../application/providers.dart';
import '../data/order_history.dart';

final _when = DateFormat('MMM d, HH:mm');

/// The customer's order history for the restaurant they currently have open,
/// with live status. Reached from the menu app bar.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(walletProvider).active;
    final orders = active == null
        ? const <PlacedOrder>[]
        : ref.watch(ordersForStorefrontProvider(active.id));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ordersTitle)),
      body: orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.ordersEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _OrderTile(order: orders[i]),
            ),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  final PlacedOrder order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Poll live while the order can still change; otherwise use the stored
    // status. The tracker also writes changes back into the history.
    final status = order.isTerminal
        ? order.status
        : (ref.watch(orderStatusTrackProvider(order.orderId)).value?.status ??
              order.status);

    return ListTile(
      leading: Icon(_icon(status), color: _color(context, status)),
      title: Text(order.restaurantLabel),
      subtitle: Text(
        '${_when.format(order.placedAt)} · ${order.total.format()}',
      ),
      trailing: status == domain.OnlineOrderStatus.ready
          ? FilledButton.tonal(
              onPressed: () => _markPickedUp(context, ref),
              child: Text(context.l10n.orderMarkPickedUp),
            )
          : Text(
              _label(context, status),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: _color(context, status)),
            ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              StatusScreen(orderId: order.orderId, total: order.total),
        ),
      ),
    );
  }

  /// Confirms pickup on the backend so the merchant sees it too, then updates
  /// the local history. Falls back with a message if the write fails.
  Future<void> _markPickedUp(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.orderMarkPickedUpFailed;
    final storefront = ref.read(storefrontProvider);
    if (storefront == null) return;
    try {
      await storefront.markPickedUp(order.orderId);
      await ref
          .read(orderHistoryProvider.notifier)
          .updateStatus(order.orderId, domain.OnlineOrderStatus.pickedUp);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  IconData _icon(domain.OnlineOrderStatus s) => switch (s) {
    domain.OnlineOrderStatus.timeProposed => Icons.schedule,
    domain.OnlineOrderStatus.accepted => Icons.restaurant,
    domain.OnlineOrderStatus.ready => Icons.check_circle,
    domain.OnlineOrderStatus.pickedUp => Icons.done_all,
    domain.OnlineOrderStatus.rejected => Icons.cancel_outlined,
    domain.OnlineOrderStatus.submitted => Icons.hourglass_top,
  };

  Color? _color(BuildContext context, domain.OnlineOrderStatus s) =>
      switch (s) {
        domain.OnlineOrderStatus.ready => context.posStatus.success,
        domain.OnlineOrderStatus.timeProposed => context.posStatus.warning,
        domain.OnlineOrderStatus.rejected => Theme.of(
          context,
        ).colorScheme.error,
        _ => Theme.of(context).colorScheme.primary,
      };

  String _label(BuildContext context, domain.OnlineOrderStatus s) =>
      switch (s) {
        domain.OnlineOrderStatus.submitted => context.l10n.orderStatusSubmitted,
        domain.OnlineOrderStatus.timeProposed =>
          context.l10n.orderStatusTimeProposed,
        domain.OnlineOrderStatus.accepted => context.l10n.orderStatusAccepted,
        domain.OnlineOrderStatus.ready => context.l10n.orderStatusReady,
        domain.OnlineOrderStatus.pickedUp => context.l10n.orderStatusPickedUp,
        domain.OnlineOrderStatus.rejected => context.l10n.orderStatusRejected,
      };
}
