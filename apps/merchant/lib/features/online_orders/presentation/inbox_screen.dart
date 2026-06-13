import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../application/providers.dart';

final _pickup = DateFormat('HH:mm');

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(onlineOrderingEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online orders'),
        actions: [
          if (enabled)
            TextButton.icon(
              onPressed: () => _publishMenu(context, ref),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Publish menu'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: !enabled
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Set up your Supabase project in Settings to accept online '
                  'preorders. The POS works fully without it.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  title: 'New preorders',
                  status: domain.OnlineOrderStatus.submitted,
                  emptyLabel: 'No new preorders.',
                  builder: (order) => _NewOrderCard(order: order),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'Preparing',
                  status: domain.OnlineOrderStatus.accepted,
                  emptyLabel: 'Nothing in progress.',
                  builder: (order) => _PreparingCard(order: order),
                ),
              ],
            ),
    );
  }

  Future<void> _publishMenu(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(inboxServiceProvider).publishMenu();
      messenger.showSnackBar(
        const SnackBar(content: Text('Menu published to your storefront.')),
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Publish failed: $e')));
    }
  }
}

class _Section extends ConsumerWidget {
  final String title;
  final domain.OnlineOrderStatus status;
  final String emptyLabel;
  final Widget Function(domain.IncomingOnlineOrder) builder;

  const _Section({
    required this.title,
    required this.status,
    required this.emptyLabel,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(onlineOrdersByStatusProvider(status));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...switch (orders) {
          AsyncData(:final value) when value.isEmpty => [Text(emptyLabel)],
          AsyncData(:final value) => value.map(builder).toList(),
          AsyncError(:final error) => [Text('Error: $error')],
          _ => const [Center(child: CircularProgressIndicator())],
        },
      ],
    );
  }
}

/// Shared rendering of a preorder's contents.
class _OrderSummary extends StatelessWidget {
  final domain.IncomingOnlineOrder order;

  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final lines = (jsonDecode(order.linesJson) as List)
        .cast<Map<String, dynamic>>()
        .map(domain.PreorderLine.fromJson)
        .toList();
    final total = lines.fold(domain.Money.zero, (sum, l) => sum + l.lineTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${order.customerName} - pickup ${_pickup.format(order.requestedPickupAt)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (order.customerPhone != null) Text(order.customerPhone!),
        const SizedBox(height: 4),
        for (final l in lines)
          Text(
            '${l.qty} x ${l.nameSnapshot}'
            '${l.modifiers.isEmpty ? '' : ' (${l.modifiers.map((m) => m.nameSnapshot).join(", ")})'}',
          ),
        const SizedBox(height: 4),
        Text(
          'Total ${total.format()} - pay at pickup',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _NewOrderCard extends ConsumerWidget {
  final domain.IncomingOnlineOrder order;

  const _NewOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OrderSummary(order: order),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _reject(context, ref),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _accept(context, ref),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(inboxServiceProvider).accept(order);
    ref.invalidate(onlineOrdersByStatusProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Accepted - added to orders.')),
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(inboxServiceProvider).reject(order.id);
    ref.invalidate(onlineOrdersByStatusProvider);
    messenger.showSnackBar(const SnackBar(content: Text('Preorder rejected.')));
  }
}

class _PreparingCard extends ConsumerWidget {
  final domain.IncomingOnlineOrder order;

  const _PreparingCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OrderSummary(order: order),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(inboxServiceProvider).markReady(order.id);
                  ref.invalidate(onlineOrdersByStatusProvider);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Customer notified: ready.')),
                  );
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Mark ready'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
