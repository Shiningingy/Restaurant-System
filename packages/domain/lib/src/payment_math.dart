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
