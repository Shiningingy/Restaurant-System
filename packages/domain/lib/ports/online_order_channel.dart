/// Status of an online preorder as it moves through the merchant flow.
///
/// [timeProposed] means the merchant couldn't meet the requested pickup time
/// and proposed a new one; the order waits for the customer to approve (->
/// accepted) or decline (-> rejected).
enum OnlineOrderStatus {
  submitted,
  timeProposed,
  accepted,
  rejected,
  ready,
  pickedUp,
}

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

  /// The new pickup time the merchant proposed, when [status] is
  /// timeProposed; null otherwise.
  final DateTime? proposedPickupAt;

  /// True when placed at an in-store self-order kiosk — eligible for
  /// auto-accept straight to the Orders board.
  final bool kiosk;

  /// Online card-payment state, set only by the restaurant's pay-online Edge
  /// Function (the trusted backend): `unpaid` (pay at counter / not yet paid),
  /// `paid` (the function verified the charge with the processor), or
  /// `refunded`. The merchant trusts `paid` to mark the local order paid.
  final String paymentStatus;

  /// The processor's transaction reference for a paid order (Moneris txn id),
  /// recorded against the local payment so a later refund can find it.
  final String? processorRef;

  const IncomingOnlineOrder({
    required this.id,
    required this.customerName,
    required this.linesJson,
    required this.requestedPickupAt,
    required this.submittedAt,
    this.customerPhone,
    this.proposedPickupAt,
    this.kiosk = false,
    this.paymentStatus = 'unpaid',
    this.processorRef,
  });

  bool get isPaidOnline => paymentStatus == 'paid';
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

  /// Atomically claims a `submitted` order for acceptance: flips it to
  /// `accepted` only if it is still `submitted`, returning true if this device
  /// won. Lets several POSes auto-accept the same kiosk order without two of
  /// them both building a local order. Returns false if already claimed.
  Future<bool> claimForAccept(String orderId);

  /// Proposes a new pickup time (status -> timeProposed); the customer then
  /// approves or declines it.
  Future<void> proposePickupTime(String orderId, DateTime proposedPickupAt);
}
