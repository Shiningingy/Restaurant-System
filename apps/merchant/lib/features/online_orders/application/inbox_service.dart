import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../orders/data/order_repository.dart';
import '../../payments/data/payment_repository.dart';
import '../../../core/settings/settings_repository.dart';
import '../data/menu_publisher.dart';
import '../drivers/supabase_online_order_channel.dart';

final _pickupFormat = DateFormat('HH:mm');

/// The merchant side of online ordering: surface incoming preorders,
/// accept one into a normal local order (so it flows through printing,
/// payment and reports like any other), reject, or push pickup status
/// back to the customer.
class InboxService {
  final domain.OnlineOrderChannel channel;
  final OrderRepository orders;
  final PaymentRepository payments;
  final SettingsRepository settings;
  final MenuPublisher publisher;

  InboxService({
    required this.channel,
    required this.orders,
    required this.payments,
    required this.settings,
    required this.publisher,
  });

  Stream<domain.IncomingOnlineOrder> watchIncoming() =>
      channel.watchIncomingOrders();

  /// Preorders in [status]. Empty when no cloud is configured. The inbox
  /// UI polls this.
  Future<List<domain.IncomingOnlineOrder>> currentByStatus(
    domain.OnlineOrderStatus status,
  ) async {
    final c = channel;
    if (c is SupabaseOnlineOrderChannel) return c.fetchByStatus(status);
    return const [];
  }

  /// Preorders currently awaiting a decision.
  Future<List<domain.IncomingOnlineOrder>> currentPending() =>
      currentByStatus(domain.OnlineOrderStatus.submitted);

  /// Publishes the current menu so the customer app can browse it. Returns the
  /// list of item photos that couldn't be uploaded (empty on a clean publish) —
  /// the menu itself still publishes regardless, so the caller can warn without
  /// blocking.
  Future<List<String>> publishMenu() async {
    final menu = await publisher.build();
    await channel.publishMenu(jsonEncode(menu.toJson()));
    return List.unmodifiable(publisher.photoErrors);
  }

  /// Turns a preorder into a normal local order (type=online). **Claims the
  /// order first** (atomic `submitted` → `accepted`) so two POSes can't both
  /// build it; returns the local order id, or **null** if another device
  /// already claimed it. Line prices use the customer's submitted snapshots;
  /// tax is applied locally (pickup is pay-at-store, tax included).
  Future<String?> accept(domain.IncomingOnlineOrder incoming) async {
    if (!await channel.claimForAccept(incoming.id)) return null;
    final lines = (jsonDecode(incoming.linesJson) as List)
        .cast<Map<String, dynamic>>()
        .map(domain.PreorderLine.fromJson)
        .toList();

    // The cloud stores pickup times as UTC; show the store's local wall clock.
    final pickup = _pickupFormat.format(incoming.requestedPickupAt.toLocal());
    final paidOnline = incoming.isPaidOnline;
    final orderId = await orders.createOrder(
      // Reuse the cloud order id locally so a later online refund can find it.
      id: incoming.id,
      type: domain.OrderType.online,
      taxRateBp: settings.taxRateBp,
      // A paid online order was charged subtotal+tax only (the customer never
      // saw a service fee), so waive it here to match what they actually paid.
      serviceFeeBp: paidOnline ? 0 : settings.serviceFeeBp,
      // Carry the customer's chosen tip so staff see it and the payment sheet
      // pre-fills it (a paid-online order already includes it in the payment).
      requestedTip: incoming.tip,
      note: 'Online: ${incoming.customerName} - pickup $pickup',
    );
    for (final line in lines) {
      await orders.addLine(
        orderId: orderId,
        item: domain.MenuItem(
          id: line.itemId,
          categoryId: '',
          name: line.nameSnapshot,
          price: line.priceSnapshot,
        ),
        selectedModifiers: [
          for (final m in line.modifiers)
            domain.Modifier(
              id: domain.newId(),
              groupId: '',
              name: m.nameSnapshot,
              priceDelta: m.priceDeltaSnapshot,
            ),
        ],
        qty: line.qty,
        note: line.note,
      );
    }
    // The order was already paid online (the Edge Function verified it with the
    // processor) — record it so the local order is born paid, not pay-at-counter.
    if (paidOnline) {
      final order = await orders.getOrder(orderId);
      if (order != null) {
        await payments.recordApproved(
          orderId: orderId,
          method: domain.PaymentMethod.online,
          amount: order.total,
          terminalRef: incoming.processorRef,
        );
      }
    }
    return orderId;
  }

  /// Auto-accepts orders that don't need a human decision straight to the
  /// Orders board: in-store **kiosk** orders (the customer is on site) and any
  /// order **already paid online** (no no-show risk). Each is claimed
  /// atomically, so several POSes polling at once never double-build the same
  /// order. Remote unpaid orders are left for manual review.
  Future<void> autoAcceptKiosk(
    List<domain.IncomingOnlineOrder> incoming,
  ) async {
    for (final o in incoming) {
      if (o.kiosk || o.isPaidOnline) await accept(o);
    }
  }

  /// Refunds a paid online order through the restaurant's pay-online Edge
  /// Function, then reverses the local payment and voids the order. The local
  /// order id equals the cloud order id (see [accept]). Returns true on success.
  Future<bool> refundOnline(String orderId) async {
    final c = channel;
    if (c is! SupabaseOnlineOrderChannel) return false;
    final ok = await c.refundOnline(orderId);
    if (ok) await payments.recordOnlineRefund(orderId);
    return ok;
  }

  Future<void> reject(String onlineOrderId) => channel.updateOrderStatus(
    onlineOrderId,
    domain.OnlineOrderStatus.rejected,
  );

  /// Proposes a new pickup time; the order waits for the customer to approve
  /// or decline (it does not become a local order until they accept).
  Future<void> proposePickupTime(String onlineOrderId, DateTime when) =>
      channel.proposePickupTime(onlineOrderId, when);

  Future<void> markReady(String onlineOrderId) =>
      channel.updateOrderStatus(onlineOrderId, domain.OnlineOrderStatus.ready);

  Future<void> markPickedUp(String onlineOrderId) => channel.updateOrderStatus(
    onlineOrderId,
    domain.OnlineOrderStatus.pickedUp,
  );
}
