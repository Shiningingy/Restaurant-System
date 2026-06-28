import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../../core/settings/providers.dart';
import '../../../core/widgets/item_name_lines.dart';
import '../../orders/application/providers.dart';
import '../application/payment_service.dart';
import '../application/providers.dart';
import 'payment_sheet.dart';

/// Split the bill by item: tick a group of lines, charge that group (it pays
/// its proportional share of tax, service fee and discount), repeat until none
/// remain. Each charge marks its lines settled so they drop out of the picker.
/// Returns the [PaymentFlowResult] that closed the order, or null if dismissed
/// before the order was fully paid.
Future<PaymentFlowResult?> showSplitBillSheet(
  BuildContext context, {
  required String orderId,
}) {
  return showDialog<PaymentFlowResult>(
    context: context,
    builder: (_) => _SplitBillSheet(orderId: orderId),
  );
}

class _SplitBillSheet extends ConsumerStatefulWidget {
  final String orderId;

  const _SplitBillSheet({required this.orderId});

  @override
  ConsumerState<_SplitBillSheet> createState() => _SplitBillSheetState();
}

class _SplitBillSheetState extends ConsumerState<_SplitBillSheet> {
  final _selected = <String>{};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = ref.watch(orderProvider(widget.orderId)).value;
    final lines =
        ref.watch(orderLinesProvider(widget.orderId)).value ?? const [];
    final payments =
        ref.watch(orderPaymentsProvider(widget.orderId)).value ?? const [];

    if (order == null) {
      return const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final balance = domain.balanceDue(
      total: order.total + order.cashRounding,
      payments: payments,
    );
    // Comped lines are free — they're never part of a split (nothing to pay).
    final active = lines
        .where((l) => l.status == domain.OrderLineStatus.active && !l.comped)
        .toList();
    final unpaid = active.where((l) => l.settledByPaymentId == null).toList();
    final paid = active.where((l) => l.settledByPaymentId != null).toList();

    // Drop any selection that's no longer selectable (settled meanwhile).
    _selected.removeWhere((id) => !unpaid.any((l) => l.id == id));

    final selectedSubtotal = unpaid
        .where((l) => _selected.contains(l.id))
        .fold(domain.Money.zero, (sum, l) => sum + l.lineTotal);

    // Selecting every remaining item pays the exact remaining balance, so
    // rounding from earlier splits is absorbed and the splits reconcile.
    final allRemaining =
        _selected.isNotEmpty && _selected.length == unpaid.length;
    final domain.Money charge;
    if (allRemaining) {
      charge = balance;
    } else {
      final share = domain.splitShare(
        orderTotal: order.total,
        orderSubtotal: order.subtotal,
        selectedSubtotal: selectedSubtotal,
      );
      // Never let a fixed-amount charge exceed what's still owed.
      charge = share > balance ? balance : share;
    }

    final showSecondary = ref.watch(nameDisplayProvider).orderScreen;

    return AlertDialog(
      title: Text(l10n.splitTitle),
      content: SizedBox(
        width: 440,
        child: unpaid.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.splitAllPaid, textAlign: TextAlign.center),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.splitHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final l in unpaid)
                          CheckboxListTile(
                            dense: true,
                            value: _selected.contains(l.id),
                            onChanged: _busy
                                ? null
                                : (v) => setState(() {
                                    if (v == true) {
                                      _selected.add(l.id);
                                    } else {
                                      _selected.remove(l.id);
                                    }
                                  }),
                            title: ItemNameLines(
                              code: l.codeSnapshot,
                              name: l.nameSnapshot,
                              nameSecondary: l.nameSecondarySnapshot,
                              showSecondary: showSecondary,
                            ),
                            subtitle: l.qty > 1
                                ? Text(l10n.ordQtyMultiplier(l.qty))
                                : null,
                            secondary: Text(l.lineTotal.format()),
                          ),
                        for (final l in paid)
                          ListTile(
                            dense: true,
                            enabled: false,
                            leading: const Icon(Icons.check_circle, size: 20),
                            title: ItemNameLines(
                              code: l.codeSnapshot,
                              name: l.nameSnapshot,
                              nameSecondary: l.nameSecondarySnapshot,
                              showSecondary: showSecondary,
                            ),
                            trailing: Text(l10n.splitPaid),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.ordBalanceDue),
                      Text(
                        balance.format(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.commonDone),
        ),
        FilledButton(
          onPressed: (_selected.isEmpty || _busy)
              ? null
              : () => _charge(order, balance, charge),
          child: Text(l10n.splitChargeSelected(charge.format())),
        ),
      ],
    );
  }

  Future<void> _charge(
    domain.Order order,
    domain.Money balance,
    domain.Money charge,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final ids = _selected.toList();
    setState(() => _busy = true);
    final result = await showPaymentSheet(
      context,
      order: order,
      balance: balance,
      fixedAmount: charge,
      settleLineIds: ids,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == null) return; // payment dismissed — stay on the picker
    switch (result.status) {
      case PaymentFlowStatus.approved:
        _selected.clear();
        if (result.orderClosed) {
          Navigator.pop(context, result); // bubble up for receipt + nav
        } else {
          setState(() {}); // settled lines drop out; pick the next group
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
