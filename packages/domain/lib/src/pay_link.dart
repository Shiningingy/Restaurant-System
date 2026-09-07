/// State of a staff-initiated **pay-by-link** payment.
///
/// Used for phone-in takeout: staff build the order at the till, send the
/// customer a link (QR at the counter, or SMS/email if they aren't there), and
/// the kitchen holds until the money has actually arrived.
///
/// The POS polls the payment session itself rather than waiting to be told, so
/// the outcome never depends on the customer's browser reporting back — they
/// can pay and close the tab immediately.
enum PayLinkStatus {
  /// A link exists and has been sent; nothing has been paid yet. Shown on the
  /// order board as an amber dot.
  pending,

  /// Confirmed paid by the processor. Green dot; the order settles like any
  /// other payment and moves on to be prepared.
  paid,

  /// The session was cancelled, expired, or otherwise will not complete. Red
  /// dot. Staff can send a fresh link or take payment another way — nothing has
  /// been charged, so this is recoverable.
  failed;

  static PayLinkStatus? fromName(String? name) {
    if (name == null) return null;
    for (final value in PayLinkStatus.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
