import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../application/payment_service.dart';
import '../application/providers.dart';

/// Collects one payment toward [order]: amount (defaults to the balance,
/// staff lower it to split the bill), optional tip, cash or card.
/// Returns null when dismissed without charging.
Future<PaymentFlowResult?> showPaymentSheet(
  BuildContext context, {
  required domain.Order order,
  required domain.Money balance,
}) {
  return showDialog<PaymentFlowResult>(
    context: context,
    builder: (context) => _PaymentSheet(order: order, balance: balance),
  );
}

class _PaymentSheet extends ConsumerStatefulWidget {
  final domain.Order order;
  final domain.Money balance;

  const _PaymentSheet({required this.order, required this.balance});

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late final TextEditingController _amount;
  final TextEditingController _tip = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: (widget.balance.cents / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _tip.dispose();
    super.dispose();
  }

  /// Validated amount + tip, or null (with [_error] set).
  (domain.Money, domain.Money)? _validate() {
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
    final tip = _tip.text.trim().isEmpty
        ? domain.Money.zero
        : domain.Money.tryParse(_tip.text);
    if (tip == null || tip.isNegative) {
      setState(() => _error = context.l10n.pmtEnterValidTip);
      return null;
    }
    return (amount, tip);
  }

  Future<void> _cash() async {
    final parsed = _validate();
    if (parsed == null) return;
    final (amount, tip) = parsed;
    setState(() => _busy = true);
    final result = await ref
        .read(paymentServiceProvider)
        .takeCash(orderId: widget.order.id, amount: amount, tip: tip);
    if (mounted) Navigator.pop(context, result);
  }

  Future<void> _card() async {
    final parsed = _validate();
    if (parsed == null) return;
    final (amount, tip) = parsed;
    setState(() => _busy = true);
    final result = await ref
        .read(paymentServiceProvider)
        .takeCard(
          orderId: widget.order.id,
          amount: amount,
          prompt: (chargeAmount) =>
              _confirmManualCharge(chargeAmount, defaultTip: tip),
        );
    if (mounted) Navigator.pop(context, result);
  }

  /// The ManualEntryTerminal prompt: staff key the amount on the
  /// standalone terminal and report what it said.
  Future<domain.PaymentResult?> _confirmManualCharge(
    domain.Money amount, {
    required domain.Money defaultTip,
  }) async {
    final tipController = TextEditingController(
      text: defaultTip.isZero
          ? ''
          : (defaultTip.cents / 100).toStringAsFixed(2),
    );
    try {
      return await showDialog<domain.PaymentResult>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.pmtKeyAmountOnTerminal(amount.format())),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.pmtKeyOnTerminalBody),
              const SizedBox(height: 16),
              TextField(
                controller: tipController,
                decoration: InputDecoration(
                  labelText: context.l10n.pmtTipFromTerminal,
                  prefixText: r'$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
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
                  tip:
                      domain.Money.tryParse(tipController.text) ??
                      domain.Money.zero,
                ),
              ),
              child: Text(context.l10n.pmtApproved),
            ),
          ],
        ),
      );
    } finally {
      tipController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final partial =
        domain.Money.tryParse(_amount.text) != widget.balance &&
        domain.Money.tryParse(_amount.text) != null;
    return AlertDialog(
      title: Text(context.l10n.pmtCollect(widget.balance.format())),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amount,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.pmtAmount,
                prefixText: r'$',
                helperText: partial
                    ? context.l10n.pmtPartialPaymentHint
                    : context.l10n.pmtLowerToSplitHint,
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
                labelText: context.l10n.pmtTipOptional,
                prefixText: r'$',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() => _error = null),
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
          child: Text(context.l10n.commonCancel),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _card,
          icon: const Icon(Icons.credit_card_outlined),
          label: Text(context.l10n.payCard),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _cash,
          icon: const Icon(Icons.payments_outlined),
          label: Text(context.l10n.payCash),
        ),
      ],
    );
  }
}
