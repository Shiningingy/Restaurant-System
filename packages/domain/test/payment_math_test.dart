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
}
