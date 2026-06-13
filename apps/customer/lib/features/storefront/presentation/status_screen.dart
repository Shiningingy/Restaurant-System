import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../application/providers.dart';

/// Live status of a placed preorder, polled from the storefront.
final _statusProvider = StreamProvider.autoDispose
    .family<domain.OnlineOrderStatus, String>((ref, orderId) {
      final storefront = ref.watch(storefrontProvider);
      if (storefront == null) return const Stream.empty();
      return storefront.watchStatus(orderId);
    });

class StatusScreen extends ConsumerWidget {
  final String orderId;
  final domain.Money total;

  const StatusScreen({super.key, required this.orderId, required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(_statusProvider(orderId)).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your preorder'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon(status), size: 72, color: _color(context, status)),
              const SizedBox(height: 16),
              Text(
                _headline(status),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_detail(status), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text(
                'Total ${total.format()} - pay at pickup',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(domain.OnlineOrderStatus? s) => switch (s) {
    domain.OnlineOrderStatus.accepted => Icons.restaurant,
    domain.OnlineOrderStatus.ready => Icons.check_circle,
    domain.OnlineOrderStatus.pickedUp => Icons.done_all,
    domain.OnlineOrderStatus.rejected => Icons.cancel_outlined,
    _ => Icons.hourglass_top,
  };

  Color? _color(BuildContext context, domain.OnlineOrderStatus? s) =>
      switch (s) {
        domain.OnlineOrderStatus.ready => Colors.green,
        domain.OnlineOrderStatus.rejected => Theme.of(
          context,
        ).colorScheme.error,
        _ => Theme.of(context).colorScheme.primary,
      };

  String _headline(domain.OnlineOrderStatus? s) => switch (s) {
    null => 'Sending your order...',
    domain.OnlineOrderStatus.submitted => 'Waiting for the restaurant',
    domain.OnlineOrderStatus.accepted => 'Accepted - being prepared',
    domain.OnlineOrderStatus.ready => 'Ready for pickup!',
    domain.OnlineOrderStatus.pickedUp => 'Picked up - enjoy!',
    domain.OnlineOrderStatus.rejected => 'Order declined',
  };

  String _detail(domain.OnlineOrderStatus? s) => switch (s) {
    domain.OnlineOrderStatus.submitted =>
      'The restaurant will confirm your order shortly.',
    domain.OnlineOrderStatus.accepted =>
      "We'll let you know when it's ready to collect.",
    domain.OnlineOrderStatus.ready => 'Head to the counter to pick up and pay.',
    domain.OnlineOrderStatus.rejected =>
      'Sorry - the restaurant could not take this order.',
    _ => '',
  };
}
