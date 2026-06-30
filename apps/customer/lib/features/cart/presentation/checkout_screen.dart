import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

import '../../../core/l10n_ext.dart';
import '../../kiosk/presentation/kiosk_thankyou_screen.dart';
import '../../orders/application/providers.dart';
import '../../orders/data/order_history.dart';
import '../../storefront/application/providers.dart';
import '../../storefront/presentation/status_screen.dart';
import '../cart.dart';
import 'payment_webview.dart';

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

  /// The tip the customer chose (on top of subtotal + tax). Zero by default.
  domain.Money _tip = domain.Money.zero;

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

  List<int> get _tipPresets =>
      ref.read(menuProvider).value?.tipPresetsBp ?? const [];

  /// Estimated tax on the current cart (basis points). The merchant applies
  /// the real tax on its side; this is only a heads-up for the customer.
  domain.Money get _estimatedTax {
    if (_taxRateBp <= 0) return domain.Money.zero;
    final cents = (ref.read(cartProvider).total.cents * _taxRateBp / 10000)
        .round();
    return domain.Money(cents);
  }

  Future<void> _place({bool payOnline = false}) async {
    final l10n = context.l10n;
    final storefront = ref.read(storefrontProvider);
    if (storefront == null) return;
    final kiosk = ref.read(kioskModeProvider);
    // On a shared kiosk a name is optional — fall back to a generic label.
    final typedName = _name.text.trim();
    final customerName = typedName.isEmpty && kiosk
        ? l10n.kioskDefaultName
        : typedName;
    if (customerName.isEmpty) {
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
        customerName: customerName,
        customerPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        customerEmail: profile.email,
        notifyByEmail:
            profile.notifyByEmail && (profile.email?.isNotEmpty ?? false),
        notifyBySms: profile.notifyBySms && _phone.text.trim().isNotEmpty,
        requestedPickupAt: _pickupDateTime,
        tip: _tip,
        lines: cart.lines.map((l) => l.toPreorderLine()).toList(),
      );
      final orderId = await storefront.submitPreorder(
        submission,
        customerUid: ref.read(storefrontConfigProvider).customerUid,
      );

      // Pay online: open Moneris's hosted page IN-APP. The webview renders it
      // with our Supabase origin (which Moneris's iframe requires) and pops back
      // `true` once the charge lands. The order isn't "placed" until paid — on
      // success we finalize; if the customer backs out we delete the still-unpaid
      // order so it never reaches the merchant, and the cart is kept.
      final url = ref.read(storefrontConfigProvider).url;
      if (payOnline && url != null) {
        if (!mounted) return;
        setState(() => _busy = false);
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => PaymentWebView(
              pageUrl: '$url/functions/v1/pay-online?order_id=$orderId',
              orderId: orderId,
            ),
          ),
        );
        if (!mounted) return;
        if (paid == true) {
          await _finalizePlaced(orderId, submission, paidOnline: true);
        } else {
          await _cancelUnpaid(orderId);
        }
        return;
      }

      await _finalizePlaced(orderId, submission);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.checkoutOrderFailed(e.toString());
        });
      }
    }
  }

  /// The order is real (placed or paid): record history, remember the customer,
  /// clear the cart, and move to the status screen.
  Future<void> _finalizePlaced(
    String orderId,
    domain.PreorderSubmission submission, {
    bool paidOnline = false,
  }) async {
    final kiosk = ref.read(kioskModeProvider);
    // A shared kiosk keeps no per-device history and doesn't remember the
    // customer (privacy between customers); it confirms and resets instead.
    if (!kiosk) {
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
    }
    ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => kiosk
            ? const KioskThankYouScreen()
            : StatusScreen(orderId: orderId, total: submission.total),
      ),
    );
  }

  /// The customer backed out of payment: delete the still-unpaid order (so it
  /// never reaches the merchant) and surface a message. The cart is untouched,
  /// so they can try again.
  Future<void> _cancelUnpaid(String orderId) async {
    try {
      await ref.read(storefrontProvider)?.cancelUnpaidOrder(orderId);
    } on Object {
      // Best-effort — RLS or the row being gone is fine; the merchant won't act
      // on an unpaid order anyway.
    }
    if (!mounted) return;
    setState(() => _error = context.l10n.checkoutPaymentNotCompleted);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    // Online card payment is offered only when the merchant enabled it and this
    // isn't a shared in-store kiosk (kiosk pays at the counter).
    final payOnlineAvailable =
        (ref.watch(menuProvider).value?.acceptsOnlinePayment ?? false) &&
        !ref.watch(kioskModeProvider);
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
          if (_tipPresets.isNotEmpty && cart.lines.isNotEmpty) ...[
            TipSelector(
              presetsBp: _tipPresets,
              subtotal: cart.total,
              tip: _tip,
              onChanged: (t) => setState(() => _tip = t),
              title: context.l10n.checkoutTipTitle,
              noTipLabel: context.l10n.checkoutNoTip,
              customLabel: context.l10n.checkoutTipCustom,
              customHint: context.l10n.checkoutTipCustomHint,
            ),
            const SizedBox(height: 16),
          ],
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
          if (!_tip.isZero) ...[
            _AmountRow(label: context.l10n.checkoutTip, amount: _tip.format()),
            const SizedBox(height: 4),
          ],
          _AmountRow(
            label: context.l10n.checkoutTotal,
            amount: (cart.total + _estimatedTax + _tip).format(),
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
          if (_busy)
            const Center(child: CircularProgressIndicator())
          // When the merchant accepts online payment, the customer pays online —
          // there is no pay-at-counter option (that's reserved for whitelisted
          // regulars, not built yet). Otherwise it's a normal pay-at-counter
          // preorder.
          else if (payOnlineAvailable)
            FilledButton.icon(
              onPressed: () => _place(payOnline: true),
              icon: const Icon(Icons.lock_outline),
              label: Text(context.l10n.checkoutPayOnline),
            )
          else
            FilledButton(
              onPressed: () => _place(),
              child: Text(context.l10n.checkoutPlacePreorder),
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
        Text(amount, style: moneyTextStyle(style)),
      ],
    );
  }
}
