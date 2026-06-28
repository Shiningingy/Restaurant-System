import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

OrderLine _line({
  required int cents,
  int qty = 1,
  OrderLineStatus status = OrderLineStatus.active,
  bool comped = false,
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
    comped: comped,
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

    test('discount comes off before tax', () {
      // $20.00 subtotal, $2.00 discount -> $18.00 taxable; 13% = 234c.
      final t = OrderTotals.compute(
        lines: [_line(cents: 2000)],
        taxRateBp: 1300,
        discount: const Money(200),
      );
      expect(t.subtotal, const Money(2000));
      expect(t.discount, const Money(200));
      expect(t.tax, const Money(234));
      expect(t.total, const Money(2034)); // 1800 + 234
    });

    test('service fee is charged on the discounted subtotal', () {
      // $10.00 subtotal, no discount, 10% service fee = 100c, 13% tax = 130c.
      final t = OrderTotals.compute(
        lines: [_line(cents: 1000)],
        taxRateBp: 1300,
        serviceFeeBp: 1000,
      );
      expect(t.serviceFee, const Money(100));
      expect(t.tax, const Money(130));
      expect(t.total, const Money(1230)); // 1000 + 130 + 100
    });

    test('comped lines are free but their worth is tallied in comps', () {
      // $10.00 paid + $4.00 comped: customer owes 10.00 + 13% tax = 1130c;
      // the comp's $4.00 is reported separately, never billed or taxed.
      final t = OrderTotals.compute(
        lines: [_line(cents: 1000), _line(cents: 400, comped: true)],
        taxRateBp: 1300,
      );
      expect(t.subtotal, const Money(1000));
      expect(t.comps, const Money(400));
      expect(t.tax, const Money(130));
      expect(t.total, const Money(1130));
    });

    test('a fully comped order owes nothing', () {
      final t = OrderTotals.compute(
        lines: [_line(cents: 800, comped: true)],
        taxRateBp: 1300,
      );
      expect(t.subtotal, Money.zero);
      expect(t.comps, const Money(800));
      expect(t.total, Money.zero);
    });

    test('discount is capped at the subtotal', () {
      final t = OrderTotals.compute(
        lines: [_line(cents: 500)],
        taxRateBp: 1300,
        discount: const Money(9999),
      );
      expect(t.discount, const Money(500));
      expect(t.total, Money.zero);
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
