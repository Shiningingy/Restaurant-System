import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../orders/application/providers.dart';
import '../../orders/data/order_history.dart';
import '../../storefront/application/providers.dart';
import '../../storefront/presentation/status_screen.dart';
import '../cart.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;

  /// The full pickup moment the customer chose. Initialised in [initState] to
  /// the earliest the restaurant allows (now + its published lead time).
  late DateTime _pickupAt;
  bool _busy = false;
  String? _error;

  /// Earliest pickup the restaurant accepts: now + the menu's lead minutes.
  DateTime get _earliest => DateTime.now().add(
    Duration(minutes: ref.read(menuProvider).value?.pickupLeadMinutes ?? 0),
  );

  @override
  void initState() {
    super.initState();
    final config = ref.read(storefrontConfigProvider);
    _name = TextEditingController(text: config.customerName ?? '');
    _phone = TextEditingController(text: config.customerPhone ?? '');
    // Default to the soonest allowed time, rounded up to the next 5 minutes.
    final soonest = _earliest;
    final rounded = soonest.add(
      Duration(minutes: (5 - soonest.minute % 5) % 5),
    );
    _pickupAt = rounded;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  DateTime get _pickupDateTime => _pickupAt;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupAt),
      helpText: context.l10n.checkoutPickupTime,
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
    // A time already past today means they mean tomorrow.
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));
    final earliest = _earliest;
    if (when.isBefore(earliest)) {
      // Too soon — snap to the earliest the restaurant allows and explain.
      setState(() {
        _pickupAt = earliest;
        _error = context.l10n.checkoutPickupTooSoon(_minutesLead);
      });
      return;
    }
    setState(() {
      _pickupAt = when;
      _error = null;
    });
  }

  int get _minutesLead => ref.read(menuProvider).value?.pickupLeadMinutes ?? 0;

  int get _taxRateBp => ref.read(menuProvider).value?.taxRateBp ?? 0;

  /// Estimated tax on the current cart (basis points). The merchant applies
  /// the real tax on its side; this is only a heads-up for the customer.
  domain.Money get _estimatedTax {
    if (_taxRateBp <= 0) return domain.Money.zero;
    final cents = (ref.read(cartProvider).total.cents * _taxRateBp / 10000)
        .round();
    return domain.Money(cents);
  }

  Future<void> _place() async {
    final l10n = context.l10n;
    final storefront = ref.read(storefrontProvider);
    if (storefront == null) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l10n.checkoutNameRequired);
      return;
    }
    final cart = ref.read(cartProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = ref.read(walletProvider).profile;
      final submission = domain.PreorderSubmission(
        customerName: _name.text.trim(),
        customerPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        customerEmail: profile.email,
        notifyByEmail:
            profile.notifyByEmail && (profile.email?.isNotEmpty ?? false),
        notifyBySms: profile.notifyBySms && _phone.text.trim().isNotEmpty,
        requestedPickupAt: _pickupDateTime,
        lines: cart.lines.map((l) => l.toPreorderLine()).toList(),
      );
      final orderId = await storefront.submitPreorder(
        submission,
        customerUid: ref.read(storefrontConfigProvider).customerUid,
      );
      final active = ref.read(walletProvider).active;
      if (active != null) {
        await ref
            .read(orderHistoryProvider.notifier)
            .add(
              PlacedOrder(
                orderId: orderId,
                storefrontId: active.id,
                restaurantLabel: active.label,
                totalCents: submission.total.cents,
                placedAt: DateTime.now(),
                status: domain.OnlineOrderStatus.submitted,
              ),
            );
      }
      await ref
          .read(walletProvider.notifier)
          .rememberCustomer(name: _name.text.trim(), phone: _phone.text.trim());
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              StatusScreen(orderId: orderId, total: submission.total),
        ),
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.checkoutOrderFailed(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.checkoutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: context.l10n.checkoutNameLabel,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: InputDecoration(
              labelText: context.l10n.checkoutPhoneLabel,
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(context.l10n.checkoutPickupTime),
            subtitle: _minutesLead > 0
                ? Text(context.l10n.checkoutPickupLead(_minutesLead))
                : null,
            trailing: Text(
              TimeOfDay.fromDateTime(_pickupAt).format(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: _pickTime,
          ),
          const Divider(height: 32),
          if (_taxRateBp > 0) ...[
            _AmountRow(
              label: context.l10n.checkoutSubtotal,
              amount: cart.total.format(),
            ),
            const SizedBox(height: 4),
            _AmountRow(
              label: context.l10n.checkoutEstimatedTax,
              amount: _estimatedTax.format(),
            ),
            const SizedBox(height: 4),
          ],
          _AmountRow(
            label: context.l10n.checkoutTotal,
            amount: (cart.total + _estimatedTax).format(),
            emphasize: true,
          ),
          const SizedBox(height: 4),
          Text(
            _taxRateBp > 0
                ? context.l10n.checkoutEstimateNote
                : context.l10n.checkoutPayAtCounter,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _place,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.checkoutPlacePreorder),
          ),
        ],
      ),
    );
  }
}

/// A label on the left, amount on the right; emphasized for the grand total.
class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool emphasize;

  const _AmountRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount, style: style),
      ],
    );
  }
}
