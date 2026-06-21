import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/item_name_lines.dart';
import '../../admin/domain/staff.dart';
import '../../admin/presentation/pin_dialog.dart';
import '../../menu/application/providers.dart';
import '../../payments/application/payment_service.dart';
import '../../payments/application/providers.dart';
import '../../payments/presentation/payment_sheet.dart';
import '../../payments/presentation/split_bill_sheet.dart';
import '../../printing/application/providers.dart';
import '../../../core/settings/providers.dart';
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
    final showSecondary = ref.watch(nameDisplayProvider).orderScreen;

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.code == null || item.code!.isEmpty
                                    ? item.name
                                    : '${item.code}  ${item.name}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (showSecondary &&
                                  item.nameSecondary != null &&
                                  item.nameSecondary!.isNotEmpty)
                                Text(
                                  item.nameSecondary!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
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
    final showSecondary = ref.watch(nameDisplayProvider).orderScreen;

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
                      title: ItemNameLines(
                        code: line.codeSnapshot,
                        name: line.nameSnapshot,
                        nameSecondary: line.nameSecondarySnapshot,
                        showSecondary: showSecondary,
                      ),
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
              if (!order.discount.isZero)
                _totalRow(
                  context,
                  context.l10n.ordDiscount,
                  domain.Money.zero - order.discount,
                ),
              if (!order.serviceFee.isZero)
                _totalRow(
                  context,
                  context.l10n.ordServiceFeePercent(
                    (order.serviceFeeBp / 100).toStringAsFixed(2),
                  ),
                  order.serviceFee,
                ),
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
              if (isOpen)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _editDiscount(context, ref, order),
                    icon: const Icon(Icons.local_offer_outlined, size: 18),
                    label: Text(
                      order.discount.isZero
                          ? context.l10n.ordAddDiscount
                          : context.l10n.ordEditDiscount,
                    ),
                  ),
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
              if (isOpen && visibleLines.length >= 2) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _splitByItem(context, ref),
                    icon: const Icon(Icons.call_split),
                    label: Text(context.l10n.ordSplitByItem),
                  ),
                ),
              ],
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
    if (!ref.read(receiptPrinterReadyProvider)) {
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

  /// Apply or change the order discount. Offers the manager-set presets plus a
  /// manual percent; a manual percent above the threshold needs a manager PIN.
  Future<void> _editDiscount(
    BuildContext context,
    WidgetRef ref,
    domain.Order order,
  ) async {
    final settings = ref.read(settingsRepositoryProvider);
    final chosenBp = await showDialog<int>(
      context: context,
      builder: (context) => _DiscountDialog(
        presetsBp: settings.discountPresetsBp,
        currentBp: order.subtotal.isZero
            ? 0
            : (order.discount.cents * 10000 / order.subtotal.cents).round(),
      ),
    );
    if (chosenBp == null) return; // cancelled
    // A manual discount above the free-staff threshold needs a manager.
    if (chosenBp > settings.discountThresholdBp) {
      if (!context.mounted) return;
      final ok = await requirePermission(
        context,
        ref,
        AppPermission.largeDiscount,
      );
      if (!ok) return;
    }
    final discount = order.subtotal.percent(chosenBp / 100);
    await ref.read(orderRepositoryProvider).setDiscount(order.id, discount);
  }

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref,
    domain.Money balance,
  ) async {
    final result = await showPaymentSheet(
      context,
      order: order,
      balance: balance,
    );
    if (context.mounted) await _applyResult(context, ref, result);
  }

  /// Split the bill by item: charge groups of lines until none remain. The
  /// sheet pops with the result that finally closes the order (if any).
  Future<void> _splitByItem(BuildContext context, WidgetRef ref) async {
    final result = await showSplitBillSheet(context, orderId: order.id);
    if (context.mounted) await _applyResult(context, ref, result);
  }

  /// Shared post-payment handling for both the single-payment and the
  /// split-by-item flows: print the receipt and leave when the order closes,
  /// otherwise surface the partial/declined/failed outcome.
  Future<void> _applyResult(
    BuildContext context,
    WidgetRef ref,
    PaymentFlowResult? result,
  ) async {
    if (result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    switch (result.status) {
      case PaymentFlowStatus.approved:
        if (result.orderClosed) {
          if (ref.read(receiptPrinterReadyProvider)) {
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

/// Picks a discount: a manager-set preset, or a manual percent. Returns the
/// chosen rate in basis points (0 removes the discount), or null if cancelled.
class _DiscountDialog extends StatefulWidget {
  final List<int> presetsBp;
  final int currentBp;

  const _DiscountDialog({required this.presetsBp, required this.currentBp});

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late final TextEditingController _manual;

  @override
  void initState() {
    super.initState();
    _manual = TextEditingController(
      text: widget.currentBp == 0 ? '' : _fmt(widget.currentBp),
    );
  }

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  static String _fmt(int bp) =>
      (bp % 100 == 0) ? '${bp ~/ 100}' : (bp / 100).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.ordDiscount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.presetsBp.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final bp in widget.presetsBp)
                  ActionChip(
                    label: Text('${_fmt(bp)}%'),
                    onPressed: () => Navigator.pop(context, bp),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _manual,
            autofocus: widget.presetsBp.isEmpty,
            decoration: InputDecoration(
              labelText: l10n.ordDiscountPercent,
              suffixText: '%',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        if (widget.currentBp != 0)
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: Text(l10n.ordRemoveDiscount),
          ),
        FilledButton(
          onPressed: () {
            final pct = double.tryParse(_manual.text.trim()) ?? 0;
            final bp = (pct * 100).round().clamp(0, 10000);
            Navigator.pop(context, bp);
          },
          child: Text(l10n.commonApply),
        ),
      ],
    );
  }
}
