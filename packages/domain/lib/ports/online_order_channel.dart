/// Status of an online preorder as it moves through the merchant flow.
enum OnlineOrderStatus { submitted, accepted, rejected, ready, pickedUp }

/// A preorder placed by the customer app, as it arrives on the merchant
/// tablet. Line details stay as JSON until Phase 6 firms up the shape —
/// this interface exists now so nothing else couples to a vendor.
class IncomingOnlineOrder {
  final String id;
  final String customerName;
  final String? customerPhone;
  final String linesJson;
  final DateTime requestedPickupAt;
  final DateTime submittedAt;

  const IncomingOnlineOrder({
    required this.id,
    required this.customerName,
    required this.linesJson,
    required this.requestedPickupAt,
    required this.submittedAt,
    this.customerPhone,
  });
}

/// The bridge between the customer app and the merchant tablet.
///
/// The restaurant's own Supabase project carries the traffic: the customer
/// app writes preorders there, the merchant app watches for them in
/// realtime and publishes menu + order status back. Preorders are
/// pay-at-pickup — no payment data flows through this channel.
///
/// Planned implementations:
///  - NoopOnlineOrderChannel (default — empty stream; POS fully functional
///    without online ordering)
///  - SupabaseOnlineOrderChannel (Phase 6)
abstract interface class OnlineOrderChannel {
  /// Realtime stream of new preorders for the merchant inbox.
  Stream<IncomingOnlineOrder> watchIncomingOrders();

  /// Publishes the current menu so the customer app can browse it.
  Future<void> publishMenu(String menuJson);

  /// Pushes accept/reject/ready/picked-up back to the customer.
  Future<void> updateOrderStatus(String orderId, OnlineOrderStatus status);
}
