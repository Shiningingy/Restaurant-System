import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

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
      setState(() => _error = 'Enter a valid amount.');
      return null;
    }
    if (amount > widget.balance) {
      setState(
        () =>
            _error = 'Amount exceeds the balance (${widget.balance.format()}).',
      );
      return null;
    }
    final tip = _tip.text.trim().isEmpty
        ? domain.Money.zero
        : domain.Money.tryParse(_tip.text);
    if (tip == null || tip.isNegative) {
      setState(() => _error = 'Enter a valid tip.');
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
          title: Text('Key ${amount.format()} on the terminal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the amount on the card terminal, then record '
                'the outcome shown on its screen.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tipController,
                decoration: const InputDecoration(
                  labelText: 'Tip from terminal (optional)',
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                domain.PaymentResult(
                  status: domain.ChargeOutcome.declined,
                  amount: amount,
                ),
              ),
              child: const Text('Declined'),
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
              child: const Text('Approved'),
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
      title: Text('Collect ${widget.balance.format()}'),
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
                labelText: 'Amount',
                prefixText: r'$',
                helperText: partial
                    ? 'Partial payment - the order stays open.'
                    : 'Lower the amount to split the bill.',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tip,
              decoration: const InputDecoration(
                labelText: 'Tip (optional)',
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
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _card,
          icon: const Icon(Icons.credit_card_outlined),
          label: const Text('Card'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _cash,
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Cash'),
        ),
      ],
    );
  }
}
