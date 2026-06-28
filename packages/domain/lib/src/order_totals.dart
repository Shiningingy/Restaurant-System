import '../entities/order.dart';
import 'money.dart';

/// Pure totals math, shared by the merchant repository and (later) the
/// customer app, so both always agree to the cent.
class OrderTotals {
  final Money subtotal;

  /// Applied discount (already capped to the subtotal).
  final Money discount;

  /// Service fee charged on the discounted subtotal.
  final Money serviceFee;
  final Money tax;
  final Money total;

  /// Total worth of comped (on-the-house) lines — what the customer would have
  /// paid for them. Not part of [subtotal]/[total] (the customer pays nothing
  /// for them); surfaced for the receipt and reports.
  final Money comps;

  const OrderTotals({
    required this.subtotal,
    required this.tax,
    required this.total,
    this.discount = Money.zero,
    this.serviceFee = Money.zero,
    this.comps = Money.zero,
  });

  /// Voided lines never count. Comped lines don't count toward what's owed
  /// either — their worth is tallied separately in [comps]. The discount comes
  /// off the subtotal *before* tax, so the customer pays tax on the lower
  /// amount; the service fee is charged on that same discounted subtotal. All
  /// rates are basis points (1300 = 13%), rounded half-up on the order subtotal
  /// — not per line.
  ///
  /// total = (subtotal − discount) + tax + serviceFee.
  static OrderTotals compute({
    required Iterable<OrderLine> lines,
    required int taxRateBp,
    Money discount = Money.zero,
    int serviceFeeBp = 0,
  }) {
    var subtotal = Money.zero;
    var comps = Money.zero;
    for (final line in lines) {
      if (line.status != OrderLineStatus.active) continue;
      if (line.comped) {
        comps += line.lineTotal;
      } else {
        subtotal += line.lineTotal;
      }
    }
    // Never discount below zero.
    final capped = discount > subtotal ? subtotal : discount;
    final discounted = subtotal - capped;
    final tax = discounted.percent(taxRateBp / 100);
    final serviceFee = discounted.percent(serviceFeeBp / 100);
    return OrderTotals(
      subtotal: subtotal,
      discount: capped,
      serviceFee: serviceFee,
      tax: tax,
      total: discounted + tax + serviceFee,
      comps: comps,
    );
  }

  /// Unit price (base + selected modifier deltas) times quantity.
  static Money lineTotal({
    required Money unitPrice,
    required Iterable<Money> modifierDeltas,
    required int qty,
  }) {
    var unit = unitPrice;
    for (final delta in modifierDeltas) {
      unit += delta;
    }
    return unit * qty;
  }
}
