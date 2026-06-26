import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/item_name_lines.dart';
import '../../admin/domain/staff.dart';
import '../../admin/presentation/pin_dialog.dart';
import '../../customer_display/application/customer_display.dart';
import '../../menu/application/providers.dart';
import '../../online_orders/application/providers.dart';
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

  /// Held so [dispose] can reach it without `ref` (the container may already be
  /// torn down by then).
  CustomerDisplayController? _display;

  @override
  void dispose() {
    // Leaving the order returns the customer display to its idle screen.
    _display?.pushOrder(null);
    super.dispose();
  }

  /// Leaves the editor back to the board. Discards the order first if it was
  /// left empty and unpaid (opened with nothing added, or every line voided),
  /// so no $0 ghost lingers on the board. Best-effort — navigation doesn't wait.
  void _leave() {
    ref.read(orderRepositoryProvider).discardIfEmpty(widget.orderId);
    context.go('/orders');
  }

  /// Sends the current order (items + total) to the customer display when it's
  /// open; a no-op otherwise.
  void _pushToDisplay() {
    final display = _display;
    if (display == null || !display.isOpen) return;
    final order = ref.read(orderProvider(widget.orderId)).value;
    if (order == null) {
      display.pushOrder(null);
      return;
    }
    final lines =
        ref.read(orderLinesProvider(widget.orderId)).value ?? const [];
    final visible = lines
        .where((l) => l.status == domain.OrderLineStatus.active)
        .toList();
    display.pushOrder({
      'lines': [
        for (final l in visible)
          {
            'qty': l.qty,
            'name': l.nameSnapshot,
            'amount': l.lineTotal.format(),
          },
      ],
      // Full breakdown so the customer sees how the total is reached, not just
      // the final number. Null fields are omitted on the display.
      'subtotal': order.subtotal.format(),
      'discount': order.discount.isZero
          ? null
          : (domain.Money.zero - order.discount).format(),
      'serviceFee': order.serviceFee.isZero ? null : order.serviceFee.format(),
      'serviceFeeBp': order.serviceFeeBp,
      'tax': order.tax.format(),
      'taxRateBp': order.taxRateBp,
      'total': order.total.format(),
    });
  }

  @override
  Widget build(BuildContext context) {
    _display ??= ref.read(customerDisplayProvider);
    final order = ref.watch(orderProvider(widget.orderId)).value;
    final lines =
        ref.watch(orderLinesProvider(widget.orderId)).value ?? const [];
    // `sent` orders (kitchen ticket printed) stay editable until paid.
    final isOpen =
        order?.status == domain.OrderStatus.open ||
        order?.status == domain.OrderStatus.sent;

    // Mirror the order to the customer display (if open) as it's rung up.
    ref.listen(orderProvider(widget.orderId), (_, _) => _pushToDisplay());
    ref.listen(orderLinesProvider(widget.orderId), (_, _) => _pushToDisplay());

    // A paid online order can be refunded through the Edge Function.
    final payments =
        ref.watch(orderPaymentsProvider(widget.orderId)).value ?? const [];
    final canRefund =
        order != null &&
        order.status != domain.OrderStatus.voided &&
        payments.any(
          (p) =>
              p.method == domain.PaymentMethod.online &&
              p.status == domain.PaymentStatus.approved,
        );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _leave),
        title: Text(_title(context, order)),
        actions: [
          // Discount moved inline (above the Tax row in the ticket); the app bar
          // keeps only the order-level void.
          if (order != null && isOpen)
            TextButton.icon(
              onPressed: () => _voidOrder(context),
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.ordVoidOrder),
            ),
          if (canRefund)
            TextButton.icon(
              onPressed: () => _refundOnline(context),
              icon: const Icon(Icons.currency_exchange),
              label: Text(context.l10n.ordRefundOnline),
            ),
          // A paid order is being prepared — "Mark finished" sends it to
          // history and off the board.
          if (order != null && order.status == domain.OrderStatus.paid)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(orderRepositoryProvider).markFinished(order.id);
                  context.go('/orders');
                },
                // Override the POS theme's 64px touch floor so it fits the
                // app bar.
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                icon: const Icon(Icons.check),
                label: Text(context.l10n.ordMarkFinished),
              ),
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
                  child: _Ticket(
                    order: order,
                    lines: lines,
                    isOpen: isOpen,
                    onEditDiscount: () => _editDiscount(context, order),
                  ),
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

  /// Refunds a paid online order through the restaurant's pay-online Edge
  /// Function, then reverses the local payment and voids the order.
  Future<void> _refundOnline(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ordRefundConfirmTitle),
        content: Text(l10n.ordRefundConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ordRefundOnline),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final ok = await ref
          .read(inboxServiceProvider)
          .refundOnline(widget.orderId);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok ? l10n.ordRefundDone : l10n.ordRefundFailed('')),
        ),
      );
      if (ok && context.mounted) context.go('/orders');
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ordRefundFailed('$e'))),
      );
    }
  }

  /// Apply or change the order discount. Offers the manager-set presets plus a
  /// manual percent; a manual percent above the threshold needs a manager PIN.
  Future<void> _editDiscount(BuildContext context, domain.Order order) async {
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
    final vertical = ref.watch(categoryVerticalProvider);
    final grid = _itemsGrid(context, items, showSecondary);

    if (vertical) {
      // A left column that can show every category at once.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 168,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _layoutToggle(context, ref, vertical),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    children: [
                      for (final c in categories)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _categoryTile(ref, c, activeCategoryId),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: grid),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrapping tiles — no horizontal scroll; falls onto more rows.
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 148),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in categories)
                          SizedBox(
                            width: 168,
                            child: _categoryTile(ref, c, activeCategoryId),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _layoutToggle(context, ref, vertical),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: grid),
      ],
    );
  }

  /// A category tile with the optional shared-code prefix box.
  Widget _categoryTile(
    WidgetRef ref,
    domain.Category c,
    String activeCategoryId,
  ) => _CategoryTile(
    label: c.name,
    letter: ref.watch(categoryCodeLetterProvider(c.id)),
    selected: c.id == activeCategoryId,
    onTap: () => onCategorySelected(c.id),
  );

  Widget _layoutToggle(BuildContext context, WidgetRef ref, bool vertical) =>
      IconButton(
        tooltip: context.l10n.ordCategoryLayout,
        icon: Icon(
          vertical ? Icons.view_stream_outlined : Icons.view_column_outlined,
        ),
        onPressed: () => ref.read(categoryVerticalProvider.notifier).toggle(),
      );

  Widget _itemsGrid(
    BuildContext context,
    List<domain.MenuItem> items,
    bool showSecondary,
  ) => GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      mainAxisExtent: 116,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ),
    itemCount: items.length,
    itemBuilder: (context, i) {
      final item = items[i];
      final hasSecondary =
          showSecondary &&
          item.nameSecondary != null &&
          item.nameSecondary!.isNotEmpty;
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onItemTapped(item) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flexible (not Expanded) so the name block takes only the room
                // it needs and the price stays pinned below it — no overlap.
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.code == null || item.code!.isEmpty
                            ? item.name
                            : '${item.code}  ${item.name}',
                        maxLines: hasSecondary ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (hasSecondary)
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// A category tile: an optional full-height **prefix box** (the shared item-code
/// letter, e.g. "P") beside the category name. Selected = filled primary (no
/// check mark). Used in both the horizontal wrap and the vertical column.
class _CategoryTile extends StatelessWidget {
  final String label;
  final String? letter;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimary : cs.onSurface;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (letter != null)
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    color: selected ? Colors.white24 : cs.primaryContainer,
                    child: Text(
                      letter!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: selected ? cs.onPrimary : cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ticket extends ConsumerWidget {
  final domain.Order order;
  final List<domain.OrderLine> lines;
  final bool isOpen;
  final VoidCallback onEditDiscount;

  const _Ticket({
    required this.order,
    required this.lines,
    required this.isOpen,
    required this.onEditDiscount,
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
                    final cs = Theme.of(context).colorScheme;
                    // A full-width row: trash · name(+modifiers) · [−] qty [+]
                    // · price. Built directly (not a ListTile) so the controls
                    // never overflow the trailing slot on a narrow ticket.
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          // Far-left trash removes the whole line in one tap.
                          if (isOpen)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: context.l10n.ordVoidLine,
                              color: cs.error,
                              onPressed: () => repo.voidLine(line.id),
                            )
                          else
                            const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ItemNameLines(
                                  code: line.codeSnapshot,
                                  name: line.nameSnapshot,
                                  nameSecondary: line.nameSecondarySnapshot,
                                  showSecondary: showSecondary,
                                ),
                                if (line.modifiers.isNotEmpty)
                                  Text(
                                    line.modifiers
                                        .map((m) => m.nameSnapshot)
                                        .join(', '),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          // Minus steps down to 1 (trash removes the line), so
                          // it disables at a qty of 1.
                          if (isOpen)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: context.l10n.ordDecrease,
                              onPressed: line.qty > 1
                                  ? () => repo.setLineQty(line.id, line.qty - 1)
                                  : null,
                            ),
                          Text(
                            '${line.qty}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (isOpen)
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  repo.setLineQty(line.id, line.qty + 1),
                            ),
                          SizedBox(
                            width: 64,
                            child: Text(
                              line.lineTotal.format(),
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodyLarge,
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
              // Discount lives inline now: an "Add discount" button when none,
              // or the applied discount (green) with a one-tap remove.
              if (isOpen) _discountControl(context, ref),
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
              // Secondary actions side by side; Pay separated below by a rule.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isOpen && visibleLines.isNotEmpty
                          ? () => _sendToKitchen(context, ref)
                          : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.print_outlined),
                      label: Text(
                        order.status == domain.OrderStatus.sent
                            ? context.l10n.ordReprintKitchenTicket
                            : context.l10n.ordSendToKitchen,
                      ),
                    ),
                  ),
                  if (isOpen && visibleLines.length >= 2) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _splitByItem(context, ref),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.call_split),
                        label: Text(context.l10n.ordSplitByItem),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: isOpen && visibleLines.isNotEmpty
                    ? () => _pay(context, ref, balance)
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                child: Text(
                  isOpen
                      ? context.l10n.ordPayAmount(balance.format())
                      : context.l10n.ordClosed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Inline discount: an "Add discount" button when there's none, otherwise the
  /// applied discount shown in success-green — tap the label to change it, the ×
  /// to remove it.
  Widget _discountControl(BuildContext context, WidgetRef ref) {
    final repo = ref.read(orderRepositoryProvider);
    if (order.discount.isZero) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onEditDiscount,
          icon: const Icon(Icons.local_offer_outlined, size: 20),
          label: Text(context.l10n.ordAddDiscount),
        ),
      );
    }
    final green = context.posStatus.success;
    final pct = order.subtotal.isZero
        ? 0
        : (order.discount.cents * 10000 / order.subtotal.cents).round() / 100;
    final pctText = pct == pct.roundToDouble()
        ? pct.toStringAsFixed(0)
        : pct.toStringAsFixed(2);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onEditDiscount,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${context.l10n.ordDiscount} ($pctText%)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: green),
              ),
            ),
          ),
        ),
        Text(
          (domain.Money.zero - order.discount).format(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: green),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          tooltip: context.l10n.ordRemoveDiscount,
          visualDensity: VisualDensity.compact,
          onPressed: () => repo.setDiscount(order.id, domain.Money.zero),
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
