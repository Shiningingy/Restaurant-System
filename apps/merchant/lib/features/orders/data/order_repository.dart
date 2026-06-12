import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';

class OrderRepository {
  final AppDatabase db;

  OrderRepository(this.db);

  // --- Creating & watching ---

  Future<String> createOrder({
    required domain.OrderType type,
    required int taxRateBp,
    String? tableId,
  }) async {
    final id = domain.newId();
    await db
        .into(db.orders)
        .insert(
          OrdersCompanion.insert(
            id: id,
            type: type,
            status: domain.OrderStatus.open,
            tableId: Value(tableId),
            createdAt: DateTime.now(),
            taxRateBp: taxRateBp,
            subtotal: domain.Money.zero,
            tax: domain.Money.zero,
            total: domain.Money.zero,
          ),
        );
    return id;
  }

  Stream<List<domain.Order>> watchOpenOrders() {
    final q = db.select(db.orders)
      ..where((t) => t.status.equalsValue(domain.OrderStatus.open))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_orderFromRow).toList());
  }

  Stream<domain.Order?> watchOrder(String orderId) {
    final q = db.select(db.orders)..where((t) => t.id.equals(orderId));
    return q.watchSingleOrNull().map(
      (r) => r == null ? null : _orderFromRow(r),
    );
  }

  /// Lines with their modifier snapshots, oldest first (ticket order).
  Stream<List<domain.OrderLine>> watchLines(String orderId) {
    final join =
        (db.select(
          db.orderLines,
        )..where((t) => t.orderId.equals(orderId))).join([
          leftOuterJoin(
            db.orderLineModifiers,
            db.orderLineModifiers.lineId.equalsExp(db.orderLines.id),
          ),
        ]);
    return join.watch().map((rows) {
      final lines = <String, domain.OrderLine>{};
      for (final row in rows) {
        final l = row.readTable(db.orderLines);
        lines.putIfAbsent(l.id, () => _lineFromRow(l));
        final m = row.readTableOrNull(db.orderLineModifiers);
        if (m != null) {
          final current = lines[l.id]!;
          lines[l.id] = current.copyWith(
            modifiers: [
              ...current.modifiers,
              domain.OrderLineModifier(
                id: m.id,
                lineId: m.lineId,
                nameSnapshot: m.nameSnapshot,
                priceDeltaSnapshot: m.priceDeltaSnapshot,
              ),
            ],
          );
        }
      }
      return lines.values.toList();
    });
  }

  // --- Mutating lines (each mutation recomputes the order totals) ---

  Future<void> addLine({
    required String orderId,
    required domain.MenuItem item,
    List<domain.Modifier> selectedModifiers = const [],
    int qty = 1,
    String? note,
  }) {
    return db.transaction(() async {
      final lineId = domain.newId();
      final lineTotal = domain.OrderTotals.lineTotal(
        unitPrice: item.price,
        modifierDeltas: selectedModifiers.map((m) => m.priceDelta),
        qty: qty,
      );
      await db
          .into(db.orderLines)
          .insert(
            OrderLinesCompanion.insert(
              id: lineId,
              orderId: orderId,
              menuItemId: item.id,
              nameSnapshot: item.name,
              priceSnapshot: item.price,
              qty: qty,
              lineTotal: lineTotal,
              status: domain.OrderLineStatus.active,
              note: Value(note),
            ),
          );
      for (final m in selectedModifiers) {
        await db
            .into(db.orderLineModifiers)
            .insert(
              OrderLineModifiersCompanion.insert(
                id: domain.newId(),
                lineId: lineId,
                nameSnapshot: m.name,
                priceDeltaSnapshot: m.priceDelta,
              ),
            );
      }
      await _recomputeTotals(orderId);
    });
  }

  Future<void> setLineQty(String lineId, int qty) {
    assert(qty > 0, 'use voidLine to remove a line');
    return db.transaction(() async {
      final line = await (db.select(
        db.orderLines,
      )..where((t) => t.id.equals(lineId))).getSingle();
      final mods = await (db.select(
        db.orderLineModifiers,
      )..where((t) => t.lineId.equals(lineId))).get();
      final lineTotal = domain.OrderTotals.lineTotal(
        unitPrice: line.priceSnapshot,
        modifierDeltas: mods.map((m) => m.priceDeltaSnapshot),
        qty: qty,
      );
      await (db.update(db.orderLines)..where((t) => t.id.equals(lineId))).write(
        OrderLinesCompanion(qty: Value(qty), lineTotal: Value(lineTotal)),
      );
      await _recomputeTotals(line.orderId);
    });
  }

  /// Voids flip status, never delete — audit trail (docs/ARCHITECTURE.md).
  Future<void> voidLine(String lineId) {
    return db.transaction(() async {
      final line = await (db.select(
        db.orderLines,
      )..where((t) => t.id.equals(lineId))).getSingle();
      await (db.update(db.orderLines)..where((t) => t.id.equals(lineId))).write(
        const OrderLinesCompanion(status: Value(domain.OrderLineStatus.voided)),
      );
      await _recomputeTotals(line.orderId);
    });
  }

  // --- Closing ---

  /// Records the payment and closes the order in one transaction.
  /// Phase 1 supports cash/manual; the PaymentTerminal port takes over
  /// the charge itself in Phase 3.
  Future<void> closeOrder({
    required String orderId,
    required domain.PaymentMethod method,
    domain.Money tip = domain.Money.zero,
  }) {
    return db.transaction(() async {
      final order = await (db.select(
        db.orders,
      )..where((t) => t.id.equals(orderId))).getSingle();
      await db
          .into(db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: domain.newId(),
              orderId: orderId,
              method: method,
              status: domain.PaymentStatus.approved,
              amount: order.total,
              tip: tip,
              createdAt: DateTime.now(),
            ),
          );
      await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
        OrdersCompanion(
          status: const Value(domain.OrderStatus.paid),
          closedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> voidOrder(String orderId) {
    return (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        status: const Value(domain.OrderStatus.voided),
        closedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Internals ---

  Future<void> _recomputeTotals(String orderId) async {
    final order = await (db.select(
      db.orders,
    )..where((t) => t.id.equals(orderId))).getSingle();
    final lines = await (db.select(
      db.orderLines,
    )..where((t) => t.orderId.equals(orderId))).get();
    final totals = domain.OrderTotals.compute(
      lines: lines.map(_lineFromRow),
      taxRateBp: order.taxRateBp,
    );
    await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        subtotal: Value(totals.subtotal),
        tax: Value(totals.tax),
        total: Value(totals.total),
      ),
    );
  }

  domain.Order _orderFromRow(OrderRow r) => domain.Order(
    id: r.id,
    type: r.type,
    status: r.status,
    tableId: r.tableId,
    createdAt: r.createdAt,
    closedAt: r.closedAt,
    taxRateBp: r.taxRateBp,
    subtotal: r.subtotal,
    tax: r.tax,
    total: r.total,
    note: r.note,
  );

  domain.OrderLine _lineFromRow(OrderLineRow r) => domain.OrderLine(
    id: r.id,
    orderId: r.orderId,
    menuItemId: r.menuItemId,
    nameSnapshot: r.nameSnapshot,
    priceSnapshot: r.priceSnapshot,
    qty: r.qty,
    lineTotal: r.lineTotal,
    status: r.status,
    note: r.note,
  );
}
