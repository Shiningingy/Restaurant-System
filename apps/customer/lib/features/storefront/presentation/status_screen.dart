import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
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
        title: Text(context.l10n.statusTitle),
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
                _headline(context, status),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_detail(context, status), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text(
                context.l10n.statusTotalPayAtPickup(total.format()),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(context.l10n.statusBackToMenu),
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

  String _headline(
    BuildContext context,
    domain.OnlineOrderStatus? s,
  ) => switch (s) {
    null => context.l10n.statusSendingHeadline,
    domain.OnlineOrderStatus.submitted => context.l10n.statusSubmittedHeadline,
    domain.OnlineOrderStatus.accepted => context.l10n.statusAcceptedHeadline,
    domain.OnlineOrderStatus.ready => context.l10n.statusReadyHeadline,
    domain.OnlineOrderStatus.pickedUp => context.l10n.statusPickedUpHeadline,
    domain.OnlineOrderStatus.rejected => context.l10n.statusRejectedHeadline,
  };

  String _detail(BuildContext context, domain.OnlineOrderStatus? s) =>
      switch (s) {
        domain.OnlineOrderStatus.submitted =>
          context.l10n.statusSubmittedDetail,
        domain.OnlineOrderStatus.accepted => context.l10n.statusAcceptedDetail,
        domain.OnlineOrderStatus.ready => context.l10n.statusReadyDetail,
        domain.OnlineOrderStatus.rejected => context.l10n.statusRejectedDetail,
        _ => '',
      };
}
