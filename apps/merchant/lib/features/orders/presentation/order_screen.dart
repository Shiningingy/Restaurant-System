import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../../core/labels.dart';
import '../../menu/application/providers.dart';
import '../../payments/application/payment_service.dart';
import '../../payments/application/providers.dart';
import '../../payments/presentation/payment_sheet.dart';
import '../../printing/application/providers.dart';
import '../../settings/application/providers.dart';
import '../application/providers.dart';
import 'modifier_picker_dialog.dart';

class OrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider(widget.orderId)).value;
    final lines =
        ref.watch(orderLinesProvider(widget.orderId)).value ?? const [];
    // `sent` orders (kitchen ticket printed) stay editable until paid.
    final isOpen =
        order?.status == domain.OrderStatus.open ||
        order?.status == domain.OrderStatus.sent;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/orders')),
        title: Text(_title(context, order)),
        actions: [
          if (isOpen)
            TextButton.icon(
              onPressed: () => _voidOrder(context),
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.ordVoidOrder),
            ),
        ],
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _MenuPicker(
                    enabled: isOpen,
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: (id) =>
                        setState(() => _selectedCategoryId = id),
                    onItemTapped: _addItem,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: _Ticket(order: order, lines: lines, isOpen: isOpen),
                ),
              ],
            ),
    );
  }

  String _title(BuildContext context, domain.Order? order) =>
      switch (order?.type) {
        domain.OrderType.dineIn => context.l10n.ordDineInTitle,
        domain.OrderType.takeout => context.l10n.ordTakeoutTitle,
        domain.OrderType.online => context.l10n.ordOnlineTitle,
        null => context.l10n.ordOrderTitle,
      };

  Future<void> _addItem(domain.MenuItem item) async {
    final menuRepo = ref.read(menuRepositoryProvider);
    final orderRepo = ref.read(orderRepositoryProvider);
    final groups = await menuRepo.getModifierGroupsForItem(item.id);

    var selected = const <domain.Modifier>[];
    if (groups.isNotEmpty) {
      if (!mounted) return;
      final picked = await showModifierPicker(
        context,
        itemName: item.name,
        groups: groups,
      );
      if (picked == null) return;
      selected = picked;
    }
    await orderRepo.addLine(
      orderId: widget.orderId,
      item: item,
      selectedModifiers: selected,
    );
  }

  Future<void> _voidOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.ordVoidConfirmTitle),
        content: Text(context.l10n.ordVoidConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.ordKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.ordVoidOrder),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(orderRepositoryProvider).voidOrder(widget.orderId);
      if (context.mounted) context.go('/orders');
    }
  }
}

class _MenuPicker extends ConsumerWidget {
  final bool enabled;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<domain.MenuItem> onItemTapped;

  const _MenuPicker({
    required this.enabled,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => c.isActive)
        .toList();
    if (categories.isEmpty) {
      return Center(child: Text(context.l10n.ordNoMenuYet));
    }
    final activeCategoryId = selectedCategoryId ?? categories.first.id;
    final items =
        (ref.watch(itemsInCategoryProvider(activeCategoryId)).value ?? const [])
            .where((i) => i.isActive)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.name),
                    selected: c.id == activeCategoryId,
                    onSelected: (_) => onCategorySelected(c.id),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisExtent: 90,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                child: InkWell(
                  onTap: enabled ? () => onItemTapped(item) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item.price.format(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Ticket extends ConsumerWidget {
  final domain.Order order;
  final List<domain.OrderLine> lines;
  final bool isOpen;

  const _Ticket({
    required this.order,
    required this.lines,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(orderRepositoryProvider);
    final visibleLines = lines
        .where((l) => l.status == domain.OrderLineStatus.active)
        .toList();
    final payments = ref.watch(orderPaymentsProvider(order.id)).value ?? [];
    final settled = domain.settledPayments(payments).toList();
    final balance = domain.balanceDue(total: order.total, payments: payments);

    return Column(
      children: [
        Expanded(
          child: visibleLines.isEmpty
              ? Center(child: Text(context.l10n.ordTapToAdd))
              : ListView.builder(
                  itemCount: visibleLines.length,
                  itemBuilder: (context, i) {
                    final line = visibleLines[i];
                    return ListTile(
                      title: Text(line.nameSnapshot),
                      subtitle: line.modifiers.isEmpty
                          ? null
                          : Text(
                              line.modifiers
                                  .map((m) => m.nameSnapshot)
                                  .join(', '),
                            ),
                      leading: isOpen
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: line.qty == 1
                                  ? context.l10n.ordVoidLine
                                  : context.l10n.ordDecrease,
                              onPressed: () => line.qty == 1
                                  ? repo.voidLine(line.id)
                                  : repo.setLineQty(line.id, line.qty - 1),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(context.l10n.ordQtyMultiplier(line.qty)),
                          if (isOpen)
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  repo.setLineQty(line.id, line.qty + 1),
                            ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              line.lineTotal.format(),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _totalRow(context, context.l10n.ordSubtotal, order.subtotal),
              _totalRow(
                context,
                context.l10n.ordTaxPercent(
                  (order.taxRateBp / 100).toStringAsFixed(2),
                ),
                order.tax,
              ),
              const SizedBox(height: 4),
              _totalRow(
                context,
                context.l10n.ordTotal,
                order.total,
                emphasized: true,
              ),
              if (settled.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (final p in settled)
                  _totalRow(
                    context,
                    context.l10n.ordPaidMethod(
                          paymentMethodLabel(context, p.method),
                        ) +
                        (p.tip.isZero
                            ? ''
                            : context.l10n.ordTipSuffix(p.tip.format())),
                    p.amount,
                  ),
                _totalRow(
                  context,
                  context.l10n.ordBalanceDue,
                  balance,
                  emphasized: true,
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isOpen && visibleLines.isNotEmpty
                      ? () => _sendToKitchen(context, ref)
                      : null,
                  icon: const Icon(Icons.print_outlined),
                  label: Text(
                    order.status == domain.OrderStatus.sent
                        ? context.l10n.ordReprintKitchenTicket
                        : context.l10n.ordSendToKitchen,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isOpen && visibleLines.isNotEmpty
                      ? () => _pay(context, ref, balance)
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                  ),
                  child: Text(
                    isOpen
                        ? context.l10n.ordPayAmount(balance.format())
                        : context.l10n.ordClosed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    domain.Money amount, {
    bool emphasized = false,
  }) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.format(), style: style),
      ],
    );
  }

  Future<void> _sendToKitchen(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (!ref.read(printerSettingsProvider).isConfigured) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ordNoPrinterConfigured)),
      );
      return;
    }
    await ref.read(printServiceProvider).printKitchenTicket(order.id);
    await ref.read(orderRepositoryProvider).markSent(order.id);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.ordKitchenTicketQueued)),
    );
  }

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref,
    domain.Money balance,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = await showPaymentSheet(
      context,
      order: order,
      balance: balance,
    );
    if (result == null) return;
    switch (result.status) {
      case PaymentFlowStatus.approved:
        if (result.orderClosed) {
          if (ref.read(printerSettingsProvider).isConfigured) {
            await ref.read(printServiceProvider).printCustomerReceipt(order.id);
          }
          if (context.mounted) context.go('/orders');
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.ordPartialPaymentRecorded)),
          );
        }
      case PaymentFlowStatus.declined:
        messenger.showSnackBar(SnackBar(content: Text(l10n.ordCardDeclined)));
      case PaymentFlowStatus.cancelled:
        break;
      case PaymentFlowStatus.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.ordPaymentFailed(result.message ?? ''))),
        );
    }
  }
}
