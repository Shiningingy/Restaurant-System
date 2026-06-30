import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import '../../../core/sync/sync_codec.dart';
import '../../../core/sync/sync_journal.dart';

/// Persists payment attempts against orders. Every terminal outcome is
/// recorded — declined attempts included — so the day's activity is
/// auditable (docs/ARCHITECTURE.md: status flips, never deletes).
class PaymentRepository {
  final AppDatabase db;
  final SyncJournal journal;

  PaymentRepository(this.db, {SyncJournal? journal})
    : journal = journal ?? SyncJournal(db);

  Stream<List<domain.Payment>> watchPayments(String orderId) {
    final q = db.select(db.payments)
      ..where((t) => t.orderId.equals(orderId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<List<domain.Payment>> paymentsForOrder(String orderId) =>
      watchPayments(orderId).first;

  /// Records an approved payment and marks the order `paid` when its balance
  /// reaches zero — one transaction, so a crash can't leave a fully paid order
  /// open. The order stays on the board (Pending) until it's finished. Returns
  /// true if this payment fully paid it.
  Future<bool> recordApproved({
    required String orderId,
    required domain.PaymentMethod method,
    required domain.Money amount,
    domain.Money tip = domain.Money.zero,

    /// A cash-rounding adjustment (signed) applied by this payment: the amount
    /// owed becomes order.total + cashRounding, so a cash total rounded down to
    /// a clean amount still settles the order. Stored on the order; usually zero.
    domain.Money cashRounding = domain.Money.zero,
    String? terminalRef,

    /// When splitting the bill by item, the lines this payment settles. They
    /// are stamped with the new payment id in the same transaction.
    List<String> settleLineIds = const [],
  }) {
    return db.transaction(() async {
      final paymentId = await _insert(
        orderId: orderId,
        method: method,
        status: domain.PaymentStatus.approved,
        amount: amount,
        tip: tip,
        terminalRef: terminalRef,
      );
      if (settleLineIds.isNotEmpty) {
        await (db.update(db.orderLines)..where((t) => t.id.isIn(settleLineIds)))
            .write(OrderLinesCompanion(settledByPaymentId: Value(paymentId)));
        // Lines changed — re-journal the order aggregate for sync.
        await journal.recordUpsert(SyncEntities.order, orderId);
      }
      // Apply any cash-rounding adjustment to the order before the settle check.
      if (!cashRounding.isZero) {
        await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
          OrdersCompanion(cashRounding: Value(cashRounding)),
        );
      }
      final order = await (db.select(
        db.orders,
      )..where((t) => t.id.equals(orderId))).getSingle();
      final paid = await _approvedTotal(orderId);
      // The order owes total + cashRounding (rounding is a small ± adjustment).
      if (paid < order.total + order.cashRounding) return false;
      await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
        OrdersCompanion(
          status: const Value(domain.OrderStatus.paid),
          paidAt: Value(DateTime.now()),
        ),
      );
      // Paying changes the order row — re-journal it for sync.
      await journal.recordUpsert(SyncEntities.order, orderId);
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
    return db.transaction(
      () => _insert(
        orderId: orderId,
        method: method,
        status: domain.PaymentStatus.declined,
        amount: amount,
        tip: domain.Money.zero,
        terminalRef: terminalRef,
      ),
    );
  }

  /// Reverses an online card payment that was refunded through the processor:
  /// flips the order's approved `online` payment(s) to `reversed` (so they
  /// leave collections) and voids the order. One transaction.
  Future<void> recordOnlineRefund(String orderId) {
    return db.transaction(() async {
      final pays =
          await (db.select(db.payments)..where(
                (t) =>
                    t.orderId.equals(orderId) &
                    t.method.equalsValue(domain.PaymentMethod.online) &
                    t.status.equalsValue(domain.PaymentStatus.approved),
              ))
              .get();
      for (final p in pays) {
        await (db.update(db.payments)..where((t) => t.id.equals(p.id))).write(
          PaymentsCompanion(status: Value(domain.PaymentStatus.reversed)),
        );
        await journal.recordUpsert(SyncEntities.payment, p.id);
      }
      await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
        OrdersCompanion(
          status: const Value(domain.OrderStatus.voided),
          closedAt: Value(DateTime.now()),
        ),
      );
      await journal.recordUpsert(SyncEntities.order, orderId);
    });
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

  /// Inserts a payment and journals it for sync, returning its id. Callers run
  /// this inside a transaction so the insert and its journal entry are atomic.
  Future<String> _insert({
    required String orderId,
    required domain.PaymentMethod method,
    required domain.PaymentStatus status,
    required domain.Money amount,
    required domain.Money tip,
    String? terminalRef,
  }) async {
    final id = domain.newId();
    await db
        .into(db.payments)
        .insert(
          PaymentsCompanion.insert(
            id: id,
            orderId: orderId,
            method: method,
            status: status,
            amount: amount,
            tip: tip,
            terminalRef: Value(terminalRef),
            createdAt: DateTime.now(),
          ),
        );
    await journal.recordUpsert(SyncEntities.payment, id);
    return id;
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
