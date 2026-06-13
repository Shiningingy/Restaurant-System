import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';

/// Persists payment attempts against orders. Every terminal outcome is
/// recorded — declined attempts included — so the day's activity is
/// auditable (docs/ARCHITECTURE.md: status flips, never deletes).
class PaymentRepository {
  final AppDatabase db;

  PaymentRepository(this.db);

  Stream<List<domain.Payment>> watchPayments(String orderId) {
    final q = db.select(db.payments)
      ..where((t) => t.orderId.equals(orderId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<List<domain.Payment>> paymentsForOrder(String orderId) =>
      watchPayments(orderId).first;

  /// Records an approved payment and closes the order when its balance
  /// reaches zero — one transaction, so a crash can't leave a fully paid
  /// order open. Returns true if the order was closed.
  Future<bool> recordApproved({
    required String orderId,
    required domain.PaymentMethod method,
    required domain.Money amount,
    domain.Money tip = domain.Money.zero,
    String? terminalRef,
  }) {
    return db.transaction(() async {
      await _insert(
        orderId: orderId,
        method: method,
        status: domain.PaymentStatus.approved,
        amount: amount,
        tip: tip,
        terminalRef: terminalRef,
      );
      final order = await (db.select(
        db.orders,
      )..where((t) => t.id.equals(orderId))).getSingle();
      final paid = await _approvedTotal(orderId);
      if (paid < order.total) return false;
      await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
        OrdersCompanion(
          status: const Value(domain.OrderStatus.paid),
          closedAt: Value(DateTime.now()),
        ),
      );
      return true;
    });
  }

  /// Audit trail for a charge the terminal declined.
  Future<void> recordDeclined({
    required String orderId,
    required domain.PaymentMethod method,
    required domain.Money amount,
    String? terminalRef,
  }) {
    return _insert(
      orderId: orderId,
      method: method,
      status: domain.PaymentStatus.declined,
      amount: amount,
      tip: domain.Money.zero,
      terminalRef: terminalRef,
    );
  }

  // --- Internals ---

  Future<domain.Money> _approvedTotal(String orderId) async {
    final rows =
        await (db.select(db.payments)..where(
              (t) =>
                  t.orderId.equals(orderId) &
                  t.status.equalsValue(domain.PaymentStatus.approved),
            ))
            .get();
    return rows.fold<domain.Money>(
      domain.Money.zero,
      (sum, r) => sum + r.amount,
    );
  }

  Future<void> _insert({
    required String orderId,
    required domain.PaymentMethod method,
    required domain.PaymentStatus status,
    required domain.Money amount,
    required domain.Money tip,
    String? terminalRef,
  }) {
    return db
        .into(db.payments)
        .insert(
          PaymentsCompanion.insert(
            id: domain.newId(),
            orderId: orderId,
            method: method,
            status: status,
            amount: amount,
            tip: tip,
            terminalRef: Value(terminalRef),
            createdAt: DateTime.now(),
          ),
        );
  }

  domain.Payment _fromRow(PaymentRow r) => domain.Payment(
    id: r.id,
    orderId: r.orderId,
    method: r.method,
    status: r.status,
    amount: r.amount,
    tip: r.tip,
    terminalRef: r.terminalRef,
    createdAt: r.createdAt,
  );
}
