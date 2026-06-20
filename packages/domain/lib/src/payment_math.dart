/// Split/partial payment arithmetic (Phase 3).
///
/// An order may be settled by several payments (split bill, partial card
/// then cash, ...). Only approved payments count toward the balance;
/// declined attempts are kept for audit and reversed payments no longer
/// count. Tips never reduce the balance — they are on top of the total.
library;

import '../entities/payment.dart';
import 'money.dart';

/// Payments that count toward settling the order.
Iterable<Payment> settledPayments(Iterable<Payment> payments) =>
    payments.where((p) => p.status == PaymentStatus.approved);

/// Sum of approved payment amounts (tips excluded).
Money paidTotal(Iterable<Payment> payments) =>
    settledPayments(payments).fold(Money.zero, (sum, p) => sum + p.amount);

/// What is still owed on the order; never negative.
Money balanceDue({required Money total, required Iterable<Payment> payments}) {
  final due = total - paidTotal(payments);
  return due.isNegative ? Money.zero : due;
}

/// The amount to charge when splitting the bill by item: a group of lines
/// worth [selectedSubtotal] out of an order whose [orderSubtotal] settles to
/// [orderTotal]. Allocated proportionally by subtotal share, so each split
/// carries its slice of tax, service fee and discount (these are all
/// proportional to the discounted subtotal, so total × share is exact before
/// rounding). Rounded half-up to the cent; the caller pays the remaining
/// [balanceDue] for the final group so the splits always reconcile exactly.
Money splitShare({
  required Money orderTotal,
  required Money orderSubtotal,
  required Money selectedSubtotal,
}) {
  if (orderSubtotal.cents <= 0) return Money.zero;
  final numerator = orderTotal.cents * selectedSubtotal.cents;
  final cents = (numerator + orderSubtotal.cents ~/ 2) ~/ orderSubtotal.cents;
  return Money(cents);
}
