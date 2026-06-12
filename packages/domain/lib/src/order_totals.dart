import '../entities/order.dart';
import 'money.dart';

/// Pure totals math, shared by the merchant repository and (later) the
/// customer app, so both always agree to the cent.
class OrderTotals {
  final Money subtotal;
  final Money tax;
  final Money total;

  const OrderTotals({
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  /// Voided lines never count. Tax rate is basis points (1300 = 13%),
  /// rounded half-up on the order subtotal — not per line — so the
  /// receipt total always equals subtotal + tax exactly.
  static OrderTotals compute({
    required Iterable<OrderLine> lines,
    required int taxRateBp,
  }) {
    var subtotal = Money.zero;
    for (final line in lines) {
      if (line.status == OrderLineStatus.active) {
        subtotal += line.lineTotal;
      }
    }
    final tax = subtotal.percent(taxRateBp / 100);
    return OrderTotals(subtotal: subtotal, tax: tax, total: subtotal + tax);
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
