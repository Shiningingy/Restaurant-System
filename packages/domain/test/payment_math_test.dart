import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

Payment payment(
  String id,
  int cents, {
  PaymentStatus status = PaymentStatus.approved,
  int tipCents = 0,
}) =>
    Payment(
      id: id,
      orderId: 'o1',
      method: PaymentMethod.cash,
      amount: Money(cents),
      tip: Money(tipCents),
      status: status,
      createdAt: DateTime(2026, 6, 12),
    );

void main() {
  const total = Money(2147);

  test('no payments: full balance due', () {
    expect(balanceDue(total: total, payments: const []), total);
  });

  test('partial payments reduce the balance', () {
    final payments = [payment('p1', 1000), payment('p2', 500)];
    expect(paidTotal(payments), const Money(1500));
    expect(balanceDue(total: total, payments: payments), const Money(647));
  });

  test('declined and reversed payments never count', () {
    final payments = [
      payment('p1', 2147, status: PaymentStatus.declined),
      payment('p2', 1000, status: PaymentStatus.reversed),
      payment('p3', 1000, status: PaymentStatus.pending),
    ];
    expect(paidTotal(payments), Money.zero);
    expect(balanceDue(total: total, payments: payments), total);
    expect(settledPayments(payments), isEmpty);
  });

  test('tips never reduce the balance', () {
    final payments = [payment('p1', 1000, tipCents: 500)];
    expect(balanceDue(total: total, payments: payments), const Money(1147));
  });

  test('balance never goes negative', () {
    final payments = [payment('p1', 3000)];
    expect(balanceDue(total: total, payments: payments), Money.zero);
  });

  group('splitShare (split bill by item)', () {
    // Order: subtotal $100.00, total $113.00 (13% tax, no discount/fee).
    const orderSubtotal = Money(10000);
    const orderTotal = Money(11300);

    test('a group pays its proportional slice of the total, tax included', () {
      // $40 of items → 40% of the $113.00 total = $45.20.
      expect(
        splitShare(
          orderTotal: orderTotal,
          orderSubtotal: orderSubtotal,
          selectedSubtotal: const Money(4000),
        ),
        const Money(4520),
      );
    });

    test('the whole order maps to the whole total', () {
      expect(
        splitShare(
          orderTotal: orderTotal,
          orderSubtotal: orderSubtotal,
          selectedSubtotal: orderSubtotal,
        ),
        orderTotal,
      );
    });

    test('rounds half-up to the cent', () {
      // $33.33 of $100 → 33.33% of $113.00 = $37.66 (37.6629 → 3766).
      expect(
        splitShare(
          orderTotal: orderTotal,
          orderSubtotal: orderSubtotal,
          selectedSubtotal: const Money(3333),
        ),
        const Money(3766),
      );
    });

    test('zero subtotal is safe', () {
      expect(
        splitShare(
          orderTotal: Money.zero,
          orderSubtotal: Money.zero,
          selectedSubtotal: Money.zero,
        ),
        Money.zero,
      );
    });
  });
}
