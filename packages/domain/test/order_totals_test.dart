import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

OrderLine _line({
  required int cents,
  int qty = 1,
  OrderLineStatus status = OrderLineStatus.active,
}) {
  return OrderLine(
    id: newId(),
    orderId: 'o1',
    menuItemId: 'i1',
    nameSnapshot: 'Item',
    priceSnapshot: Money(cents),
    qty: qty,
    lineTotal: Money(cents * qty),
    status: status,
  );
}

void main() {
  group('OrderTotals.compute', () {
    test('sums active lines and applies basis-point tax half-up', () {
      // $9.99 + $5.00 = $14.99; 13% HST = 194.87c -> 195c
      final t = OrderTotals.compute(
        lines: [_line(cents: 999), _line(cents: 500)],
        taxRateBp: 1300,
      );
      expect(t.subtotal, const Money(1499));
      expect(t.tax, const Money(195));
      expect(t.total, const Money(1694));
    });

    test('voided lines are excluded', () {
      final t = OrderTotals.compute(
        lines: [
          _line(cents: 1000),
          _line(cents: 9999, status: OrderLineStatus.voided),
        ],
        taxRateBp: 1300,
      );
      expect(t.subtotal, const Money(1000));
      expect(t.total, const Money(1130));
    });

    test('zero tax rate', () {
      final t = OrderTotals.compute(lines: [_line(cents: 750)], taxRateBp: 0);
      expect(t.tax, Money.zero);
      expect(t.total, const Money(750));
    });
  });

  group('OrderTotals.lineTotal', () {
    test('adds modifier deltas to the unit price before multiplying', () {
      // (base 10.00 + size +2.00 - promo 0.50) * 3 = 34.50
      final total = OrderTotals.lineTotal(
        unitPrice: const Money(1000),
        modifierDeltas: const [Money(200), Money(-50)],
        qty: 3,
      );
      expect(total, const Money(3450));
    });
  });
}
