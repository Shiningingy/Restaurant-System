import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../application/payment_service.dart';
import '../application/providers.dart';

/// Collects one payment toward [order]: amount (defaults to the balance,
/// staff lower it to split the bill), optional cash-tendered for change, cash
/// or card. Returns null when dismissed without charging.
///
/// When [fixedAmount] is set (split-by-item), the amount is locked to it and
/// [settleLineIds] are the order lines this payment settles.
Future<PaymentFlowResult?> showPaymentSheet(
  BuildContext context, {
  required domain.Order order,
  required domain.Money balance,
  domain.Money? fixedAmount,
  List<String> settleLineIds = const [],
}) {
  return showDialog<PaymentFlowResult>(
    context: context,
    builder: (context) => _PaymentSheet(
      order: order,
      balance: balance,
      fixedAmount: fixedAmount,
      settleLineIds: settleLineIds,
    ),
  );
}

class _PaymentSheet extends ConsumerStatefulWidget {
  final domain.Order order;
  final domain.Money balance;
  final domain.Money? fixedAmount;
  final List<String> settleLineIds;

  const _PaymentSheet({
    required this.order,
    required this.balance,
    required this.fixedAmount,
    required this.settleLineIds,
  });

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late final TextEditingController _amount;

  /// Optional "cash tendered" — only a change-due aid; never the charged
  /// amount, so the balance math stays exact.
  late final TextEditingController _tendered;

  /// Optional tip on top of the amount (cash/keyed card) — recorded and
  /// printed on the receipt, never reduces the balance.
  late final TextEditingController _tip;
  String? _error;
  bool _busy = false;

  bool get _locked => widget.fixedAmount != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.fixedAmount ?? widget.balance;
    _amount = TextEditingController(
      text: (initial.cents / 100).toStringAsFixed(2),
    );
    _tendered = TextEditingController();
    // Pre-fill the tip the customer chose at the kiosk / online checkout so
    // staff can confirm it (only on a whole-order payment, not a split share).
    final requested = widget.order.requestedTip;
    _tip = TextEditingController(
      text: (!_locked && !requested.isZero)
          ? (requested.cents / 100).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _tendered.dispose();
    _tip.dispose();
    super.dispose();
  }

  /// The entered tip, or zero when blank/invalid.
  domain.Money get _tipAmount =>
      domain.Money.tryParse(_tip.text) ?? domain.Money.zero;

  /// The amount that will be charged, with no side effects (for the live
  /// change readout). A locked sheet always charges [widget.fixedAmount].
  domain.Money? get _chargeAmount =>
      widget.fixedAmount ?? domain.Money.tryParse(_amount.text);

  /// Validated amount, or null (with [_error] set). The amount may be lowered
  /// to split the bill, but never raised above the balance — the price itself
  /// is fixed (only discounts change it).
  domain.Money? _validate() {
    if (_locked) return widget.fixedAmount;
    final amount = domain.Money.tryParse(_amount.text);
    if (amount == null || amount.isZero || amount.isNegative) {
      setState(() => _error = context.l10n.pmtEnterValidAmount);
      return null;
    }
    if (amount > widget.balance) {
      setState(
        () => _error = context.l10n.pmtAmountExceedsBalance(
          widget.balance.format(),
        ),
      );
      return null;
    }
    return amount;
  }

  Future<void> _cash() async {
    final amount = _validate();
    if (amount == null) return;
    setState(() => _busy = true);
    final result = await ref
        .read(paymentServiceProvider)
        .takeCash(
          orderId: widget.order.id,
          amount: amount,
          tip: _tipAmount,
          settleLineIds: widget.settleLineIds,
        );
    if (mounted) Navigator.pop(context, result);
  }

  Future<void> _card() async {
    final amount = _validate();
    if (amount == null) return;
    setState(() => _busy = true);
    final result = await ref
        .read(paymentServiceProvider)
        .takeCard(
          orderId: widget.order.id,
          amount: amount,
          tip: _tipAmount,
          prompt: _confirmManualCharge,
          settleLineIds: widget.settleLineIds,
        );
    if (mounted) Navigator.pop(context, result);
  }

  /// The ManualEntryTerminal prompt: staff key the amount on the standalone
  /// terminal and report what it said (approved / declined).
  Future<domain.PaymentResult?> _confirmManualCharge(
    domain.Money amount,
  ) async {
    return showDialog<domain.PaymentResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.pmtKeyAmountOnTerminal(amount.format())),
        content: Text(context.l10n.pmtKeyOnTerminalBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              domain.PaymentResult(
                status: domain.ChargeOutcome.declined,
                amount: amount,
              ),
            ),
            child: Text(context.l10n.pmtDeclined),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              domain.PaymentResult(
                status: domain.ChargeOutcome.approved,
                amount: amount,
              ),
            ),
            child: Text(context.l10n.pmtApproved),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final partial =
        !_locked &&
        domain.Money.tryParse(_amount.text) != widget.balance &&
        domain.Money.tryParse(_amount.text) != null;

    // Live change-due: tendered minus what the customer owes in cash —
    // the charged amount plus any tip they're handing over.
    final charge = _chargeAmount;
    final cashNeeded = charge == null ? null : charge + _tipAmount;
    final tendered = domain.Money.tryParse(_tendered.text);
    final change =
        (cashNeeded != null && tendered != null && tendered >= cashNeeded)
        ? tendered - cashNeeded
        : null;

    return AlertDialog(
      title: Text(l10n.pmtCollect(widget.balance.format())),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_locked && widget.settleLineIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.pmtPayingForItems(widget.settleLineIds.length),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            TextField(
              controller: _amount,
              autofocus: !_locked,
              readOnly: _locked,
              decoration: InputDecoration(
                labelText: l10n.pmtAmount,
                prefixText: r'$',
                helperText: _locked
                    ? null
                    : (partial
                          ? l10n.pmtPartialPaymentHint
                          : l10n.pmtLowerToSplitHint),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tip,
              decoration: InputDecoration(
                labelText: l10n.pmtTip,
                prefixText: r'$',
                helperText: l10n.pmtTipHint,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tendered,
              decoration: InputDecoration(
                labelText: l10n.pmtCashTendered,
                prefixText: r'$',
                helperText: change != null
                    ? l10n.pmtChangeDue(change.format())
                    : null,
                helperStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _card,
          icon: const Icon(Icons.credit_card_outlined),
          label: Text(l10n.payCard),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _cash,
          icon: const Icon(Icons.payments_outlined),
          label: Text(l10n.payCash),
        ),
      ],
    );
  }
}
