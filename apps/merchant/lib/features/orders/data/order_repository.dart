import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import '../../../core/sync/sync_codec.dart';
import '../../../core/sync/sync_journal.dart';

class OrderRepository {
  final AppDatabase db;
  final SyncJournal journal;

  OrderRepository(this.db, {SyncJournal? journal})
    : journal = journal ?? SyncJournal(db);

  /// Re-journals the whole order aggregate (order + lines + modifiers) as
  /// one upsert — called at the end of every mutation so the change feed
  /// always carries the order's complete current state.
  Future<void> _journalOrder(String orderId) =>
      journal.recordUpsert(SyncEntities.order, orderId);

  // --- Creating & watching ---

  Future<String> createOrder({
    required domain.OrderType type,
    required int taxRateBp,
    int serviceFeeBp = 0,
    String? tableId,
    String? note,
  }) async {
    final id = domain.newId();
    await db.transaction(() async {
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
              serviceFeeBp: Value(serviceFeeBp),
              subtotal: domain.Money.zero,
              tax: domain.Money.zero,
              total: domain.Money.zero,
              note: Value(note),
            ),
          );
      await _journalOrder(id);
    });
    return id;
  }

  /// Sets the order's discount (off the subtotal, before tax) and recomputes
  /// the totals. Capped to the subtotal by the totals math.
  Future<void> setDiscount(String orderId, domain.Money discount) async {
    await db.transaction(() async {
      await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
        OrdersCompanion(discount: Value(discount)),
      );
      await _recomputeTotals(orderId);
      await _journalOrder(orderId);
    });
  }

  /// Active orders for the board: `open` plus `sent` (sent to kitchen but
  /// not yet paid — still editable).
  Stream<List<domain.Order>> watchOpenOrders() {
    final q = db.select(db.orders)
      ..where(
        (t) => t.status.isInValues([
          domain.OrderStatus.open,
          domain.OrderStatus.sent,
        ]),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_orderFromRow).toList());
  }

  Future<domain.Order?> getOrder(String orderId) async {
    final row = await (db.select(
      db.orders,
    )..where((t) => t.id.equals(orderId))).getSingleOrNull();
    return row == null ? null : _orderFromRow(row);
  }

  /// One-shot snapshot of [watchLines] — used when rendering tickets.
  Future<List<domain.OrderLine>> getLines(String orderId) =>
      watchLines(orderId).first;

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

  /// Adds [item] to the order. If an active line already holds the **same**
  /// item with the same modifiers and note, its quantity is bumped instead of
  /// adding a duplicate line (3 taps of Burger → one `3 x Burger`). Lines that
  /// differ in modifiers or note stay separate.
  Future<void> addLine({
    required String orderId,
    required domain.MenuItem item,
    List<domain.Modifier> selectedModifiers = const [],
    int qty = 1,
    String? note,
  }) {
    return db.transaction(() async {
      final wantedSig = _lineSignature(
        item.id,
        note,
        selectedModifiers.map((m) => (m.name, m.priceDelta)),
      );
      final existing = await (db.select(
        db.orderLines,
      )..where((t) => t.orderId.equals(orderId))).get();
      for (final line in existing) {
        if (line.status != domain.OrderLineStatus.active) continue;
        if (line.menuItemId != item.id) continue;
        final mods = await (db.select(
          db.orderLineModifiers,
        )..where((t) => t.lineId.equals(line.id))).get();
        final sig = _lineSignature(
          line.menuItemId,
          line.note,
          mods.map((m) => (m.nameSnapshot, m.priceDeltaSnapshot)),
        );
        if (sig != wantedSig) continue;
        // Found a match — stack onto it, keeping the original price snapshot.
        final newQty = line.qty + qty;
        final lineTotal = domain.OrderTotals.lineTotal(
          unitPrice: line.priceSnapshot,
          modifierDeltas: mods.map((m) => m.priceDeltaSnapshot),
          qty: newQty,
        );
        await (db.update(
          db.orderLines,
        )..where((t) => t.id.equals(line.id))).write(
          OrderLinesCompanion(qty: Value(newQty), lineTotal: Value(lineTotal)),
        );
        await _recomputeTotals(orderId);
        await _journalOrder(orderId);
        return;
      }

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
              codeSnapshot: Value(item.code),
              nameSecondarySnapshot: Value(item.nameSecondary),
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
      await _journalOrder(orderId);
    });
  }

  /// A canonical key for "this is the same orderable thing": item + note +
  /// the multiset of modifier (name, price-delta) pairs. Order-independent so
  /// the same modifiers picked in any order still merge.
  static String _lineSignature(
    String menuItemId,
    String? note,
    Iterable<(String, domain.Money)> modifiers,
  ) {
    final mods = modifiers.map((m) => '${m.$1}=${m.$2.cents}').toList()..sort();
    return '$menuItemId|${(note ?? '').trim()}|${mods.join(',')}';
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
      await _journalOrder(line.orderId);
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
      await _journalOrder(line.orderId);
    });
  }

  /// Marks an open order as sent to the kitchen (Phase 2 — printing the
  /// kitchen ticket). Idempotent for already-sent orders.
  Future<void> markSent(String orderId) {
    return db.transaction(() async {
      final changed =
          await (db.update(db.orders)..where(
                (t) =>
                    t.id.equals(orderId) &
                    t.status.equalsValue(domain.OrderStatus.open),
              ))
              .write(
                const OrdersCompanion(status: Value(domain.OrderStatus.sent)),
              );
      if (changed > 0) await _journalOrder(orderId);
    });
  }

  // Closing an order now lives in PaymentRepository.recordApproved
  // (Phase 3): the order closes when its payment balance reaches zero.

  Future<void> voidOrder(String orderId) {
    return db.transaction(() async {
      await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
        OrdersCompanion(
          status: const Value(domain.OrderStatus.voided),
          closedAt: Value(DateTime.now()),
        ),
      );
      await _journalOrder(orderId);
    });
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
      discount: order.discount,
      serviceFeeBp: order.serviceFeeBp,
    );
    await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        subtotal: Value(totals.subtotal),
        discount: Value(totals.discount),
        serviceFee: Value(totals.serviceFee),
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
    serviceFeeBp: r.serviceFeeBp,
    subtotal: r.subtotal,
    discount: r.discount,
    serviceFee: r.serviceFee,
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
    codeSnapshot: r.codeSnapshot,
    nameSecondarySnapshot: r.nameSecondarySnapshot,
    note: r.note,
  );
}
