import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import 'package:restaurant_ui/restaurant_ui.dart';

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
      appBar: AppBar(title: Text(context.l10n.inboxTitle)),
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
                  icon: Icons.inbox,
                  accent: context.posStatus.info,
                  status: domain.OnlineOrderStatus.submitted,
                  emptyLabel: context.l10n.inboxNoNewPreorders,
                  builder: (order) => _NewOrderCard(order: order),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: context.l10n.inboxAwaitingApproval,
                  icon: Icons.hourglass_top,
                  accent: context.posStatus.warning,
                  status: domain.OnlineOrderStatus.timeProposed,
                  emptyLabel: context.l10n.inboxNoneAwaiting,
                  builder: (order) => _AwaitingCard(order: order),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: context.l10n.inboxPreparing,
                  icon: Icons.soup_kitchen,
                  accent: context.posStatus.warning,
                  status: domain.OnlineOrderStatus.accepted,
                  emptyLabel: context.l10n.inboxNothingInProgress,
                  builder: (order) => _PreparingCard(order: order),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: context.l10n.inboxReady,
                  icon: Icons.check_circle,
                  accent: context.posStatus.success,
                  status: domain.OnlineOrderStatus.ready,
                  emptyLabel: context.l10n.inboxNoneReady,
                  builder: (order) => _ReadyCard(order: order),
                ),
              ],
            ),
    );
  }
}

class _Section extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final domain.OnlineOrderStatus status;
  final String emptyLabel;
  final Widget Function(domain.IncomingOnlineOrder) builder;

  const _Section({
    required this.title,
    required this.icon,
    required this.accent,
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
        Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
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
            _pickup.format(order.requestedPickupAt.toLocal()),
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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _reject(context, ref),
                  child: Text(context.l10n.inboxReject),
                ),
                TextButton(
                  onPressed: () => _proposeTime(context, ref),
                  child: Text(context.l10n.inboxProposeTime),
                ),
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

  Future<void> _proposeTime(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(order.requestedPickupAt.toLocal()),
      helpText: l10n.inboxProposeTime,
    );
    if (picked == null) return;
    final now = DateTime.now();
    var when = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));
    try {
      await ref.read(inboxServiceProvider).proposePickupTime(order.id, when);
      ref.invalidate(onlineOrdersByStatusProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxTimeProposed)));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxError('$e'))));
    }
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(inboxServiceProvider).accept(order);
      ref.invalidate(onlineOrdersByStatusProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxAcceptedAdded)));
    } on Object catch (e) {
      // Surface the failure — a swallowed error would leave the order stuck in
      // the cloud at `submitted` with no hint why.
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxError('$e'))));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(inboxServiceProvider).reject(order.id);
      ref.invalidate(onlineOrdersByStatusProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.inboxPreorderRejected)),
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxError('$e'))));
    }
  }
}

/// A preorder where we proposed a new time and are waiting on the customer.
class _AwaitingCard extends StatelessWidget {
  final domain.IncomingOnlineOrder order;

  const _AwaitingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final proposed = order.proposedPickupAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderSummary(order: order),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.hourglass_top, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    proposed == null
                        ? context.l10n.inboxAwaitingApproval
                        : context.l10n.inboxProposedWaiting(
                            _pickup.format(proposed.toLocal()),
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                  try {
                    await ref.read(inboxServiceProvider).markReady(order.id);
                    ref.invalidate(onlineOrdersByStatusProvider);
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.inboxCustomerNotifiedReady)),
                    );
                  } on Object catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.inboxError('$e'))),
                    );
                  }
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

/// A preorder that's ready for the customer to collect — mark it picked up to
/// close it out and clear it from the board.
class _ReadyCard extends ConsumerWidget {
  final domain.IncomingOnlineOrder order;

  const _ReadyCard({required this.order});

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
                  try {
                    await ref.read(inboxServiceProvider).markPickedUp(order.id);
                    ref.invalidate(onlineOrdersByStatusProvider);
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.inboxMarkedPickedUp)),
                    );
                  } on Object catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.inboxError('$e'))),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(context.l10n.inboxMarkPickedUp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
