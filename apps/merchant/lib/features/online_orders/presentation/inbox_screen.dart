import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../../core/settings/providers.dart';
import '../application/providers.dart';

final _pickup = DateFormat('HH:mm');

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  /// Order ids seen on the previous poll; null until the first snapshot so we
  /// don't chime for orders that were already waiting when the inbox opened.
  Set<String>? _seenSubmitted;

  void _onSubmittedChanged(
    AsyncValue<List<domain.IncomingOnlineOrder>>? _,
    AsyncValue<List<domain.IncomingOnlineOrder>> next,
  ) {
    final value = next.value;
    if (value == null) return;
    final ids = value.map((o) => o.id).toSet();
    final previous = _seenSubmitted;
    _seenSubmitted = ids;
    if (previous == null) return; // first snapshot: establish a baseline only
    final fresh = ids.difference(previous);
    if (fresh.isNotEmpty &&
        ref.read(onlineOrderSettingsProvider).newOrderSound) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(onlineOrderingEnabledProvider);
    if (enabled) {
      ref.listen(
        onlineOrdersByStatusProvider(domain.OnlineOrderStatus.submitted),
        _onSubmittedChanged,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.inboxTitle),
        actions: [
          if (enabled)
            TextButton.icon(
              onPressed: () => _publishMenu(context, ref),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(context.l10n.inboxPublishMenu),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: !enabled
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.inboxDisabledHint,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  title: context.l10n.inboxNewPreorders,
                  status: domain.OnlineOrderStatus.submitted,
                  emptyLabel: context.l10n.inboxNoNewPreorders,
                  builder: (order) => _NewOrderCard(order: order),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: context.l10n.inboxPreparing,
                  status: domain.OnlineOrderStatus.accepted,
                  emptyLabel: context.l10n.inboxNothingInProgress,
                  builder: (order) => _PreparingCard(order: order),
                ),
              ],
            ),
    );
  }

  Future<void> _publishMenu(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(inboxServiceProvider).publishMenu();
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxMenuPublished)));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.inboxPublishFailed('$e'))),
      );
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
          AsyncError(:final error) => [Text(context.l10n.inboxError('$error'))],
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
          context.l10n.inboxCustomerPickup(
            order.customerName,
            _pickup.format(order.requestedPickupAt),
          ),
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
          context.l10n.inboxTotalPayAtPickup(total.format()),
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
                  child: Text(context.l10n.inboxReject),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _accept(context, ref),
                  child: Text(context.l10n.inboxAccept),
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
    final l10n = context.l10n;
    await ref.read(inboxServiceProvider).accept(order);
    ref.invalidate(onlineOrdersByStatusProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.inboxAcceptedAdded)));
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    await ref.read(inboxServiceProvider).reject(order.id);
    ref.invalidate(onlineOrdersByStatusProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.inboxPreorderRejected)));
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
                  final l10n = context.l10n;
                  await ref.read(inboxServiceProvider).markReady(order.id);
                  ref.invalidate(onlineOrdersByStatusProvider);
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.inboxCustomerNotifiedReady)),
                  );
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(context.l10n.inboxMarkReady),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
