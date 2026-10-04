import 'dart:async';

import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../online_orders/drivers/supabase_online_order_channel.dart';
import '../../orders/data/order_repository.dart';
import '../data/payment_repository.dart';

/// Staff-sent **payment links** for orders built at the till — a phone-in
/// takeout order, where the money should arrive before the kitchen starts.
///
/// Staff mint a link and either show it as a QR at the counter or send it by
/// SMS/email; this service then polls until the customer pays.
///
/// Polling (rather than waiting to be told) is deliberate: the till asks the
/// processor directly, so the outcome never depends on the customer's browser
/// coming back to us — they can pay and immediately close the tab. It also
/// means no webhook, and therefore no public endpoint to secure.
class PayLinkService {
  final domain.OnlineOrderChannel channel;
  final OrderRepository orders;
  final PaymentRepository payments;
  final Duration pollInterval;

  Timer? _timer;

  PayLinkService({
    required this.channel,
    required this.orders,
    required this.payments,
    this.pollInterval = const Duration(seconds: 5),
  });

  /// Pay-by-link rides the restaurant's own Supabase project, so it is only
  /// available once cloud ordering is configured.
  SupabaseOnlineOrderChannel? get _remote {
    final c = channel;
    return c is SupabaseOnlineOrderChannel ? c : null;
  }

  bool get isAvailable => _remote != null;

  /// Mints a link for [orderId] and marks the order as awaiting payment (the
  /// amber dot). Returns the URL to show as a QR or send to the customer.
  Future<String> createLink({
    required String orderId,
    required domain.Money amount,
    String? label,
  }) async {
    final remote = _remote;
    if (remote == null) {
      throw const domain.SyncException('online ordering is not configured');
    }
    final link = await remote.createPayLink(
      orderId: orderId,
      amountCents: amount.cents,
      label: label,
    );
    await orders.setPayLink(orderId, link.sessionId);
    return link.url;
  }

  /// Sends an already-minted link to the customer by email and/or SMS.
  ///
  /// The message text comes from the caller so it can be localized — this
  /// service has no business knowing what language the shop speaks.
  ///
  /// Returns how many channels were actually attempted. **Zero means neither
  /// email nor SMS is configured**, which staff need told: the send silently
  /// did nothing, and the customer is waiting for a text that will never come.
  Future<int> sendLink({
    required String message,
    String? email,
    String? phone,
    String? subject,
  }) async {
    final remote = _remote;
    if (remote == null) {
      throw const domain.SyncException('online ordering is not configured');
    }
    return remote.sendMessage(
      message: message,
      email: email,
      phone: phone,
      subject: subject,
    );
  }

  /// Begins polling in the background. Safe to call repeatedly.
  void start() {
    _timer ??= Timer.periodic(pollInterval, (_) => pollOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Checks every order still waiting on a link.
  ///
  /// Failures are swallowed **per order**: a flaky connection must never take
  /// the till down or stop the other orders being checked, and the next tick
  /// simply tries again.
  Future<void> pollOnce() async {
    final remote = _remote;
    if (remote == null) return;
    final pending = await orders.pendingPayLinks();
    for (final link in pending) {
      try {
        final result = await remote.payLinkStatus(link.sessionId);
        switch (result.status) {
          case domain.PayLinkStatus.pending:
            break;
          case domain.PayLinkStatus.paid:
            await _settle(link.orderId, result);
          case domain.PayLinkStatus.failed:
            await orders.setPayLinkStatus(
              link.orderId,
              domain.PayLinkStatus.failed,
            );
        }
      } on Object {
        // Transient — leave it pending and retry on the next tick.
      }
    }
  }

  /// Records the payment so the order settles exactly like any other tender.
  ///
  /// Records what the PROCESSOR says was charged, not what the order currently
  /// totals: staff may have edited the order after the link went out, and the
  /// money that actually moved is the money that should be recorded.
  Future<void> _settle(
    String orderId,
    ({
      domain.PayLinkStatus status,
      String? paymentIntentId,
      domain.Money? amount,
    })
    result,
  ) async {
    final order = await orders.getOrder(orderId);
    if (order == null) return;

    // Already settled some other way (staff took cash while the customer
    // dithered). Mark the link paid so the dot is honest, but never record a
    // second payment against a closed order.
    if (order.status == domain.OrderStatus.paid ||
        order.status == domain.OrderStatus.done) {
      await orders.setPayLinkStatus(orderId, domain.PayLinkStatus.paid);
      return;
    }

    await payments.recordApproved(
      orderId: orderId,
      method: domain.PaymentMethod.online,
      amount: result.amount ?? order.total,
      terminalRef: result.paymentIntentId,
    );
    await orders.setPayLinkStatus(orderId, domain.PayLinkStatus.paid);
  }
}
