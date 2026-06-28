import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';

/// One payment method's line on the Z-report: what was collected on the
/// terminal/drawer that day, tips included.
class MethodTotals {
  final domain.PaymentMethod method;
  final int count;
  final domain.Money amount;
  final domain.Money tips;

  const MethodTotals({
    required this.method,
    required this.count,
    required this.amount,
    required this.tips,
  });
}

/// Sales count for a single menu item (by name snapshot).
class ItemSales {
  final String name;
  final int qty;
  final domain.Money revenue;

  const ItemSales({
    required this.name,
    required this.qty,
    required this.revenue,
  });
}

/// End-of-day (Z-report style) summary for one calendar day.
class DailyReport {
  final DateTime day;
  final int ordersPaid;
  final int ordersVoided;

  /// Sales side — orders *closed as paid* within [day].
  final domain.Money gross;
  final domain.Money subtotal;
  final domain.Money tax;

  /// Worth of items given away on the house that day — not part of [gross]
  /// (the customer paid nothing), tracked so giveaways are visible.
  final domain.Money comps;

  /// Drawer side — approved payments *taken* within [day], tips included.
  /// Can differ from the sales side when a split bill straddles midnight.
  final List<MethodTotals> collected;

  final List<ItemSales> itemSales;

  const DailyReport({
    required this.day,
    required this.ordersPaid,
    required this.ordersVoided,
    required this.gross,
    required this.subtotal,
    required this.tax,
    required this.comps,
    required this.collected,
    required this.itemSales,
  });

  domain.Money get collectedTotal =>
      collected.fold(domain.Money.zero, (s, m) => s + m.amount);

  domain.Money get tipsTotal =>
      collected.fold(domain.Money.zero, (s, m) => s + m.tips);
}

/// Read-only reporting queries over the live schema — no derived tables
/// (docs/ARCHITECTURE.md). Reports never mutate anything.
class ReportsRepository {
  final AppDatabase db;

  ReportsRepository(this.db);

  /// Z-report for the local calendar day containing [day].
  Future<DailyReport> dailyReport(DateTime day) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));

    // Sales: every order paid that day — whether it's still being prepared
    // (`paid`) or finished (`done`) — bucketed by when it was paid.
    final paid =
        await (db.select(db.orders)..where(
              (t) =>
                  t.paidAt.isBiggerOrEqualValue(from) &
                  t.paidAt.isSmallerThanValue(to) &
                  t.status.isInValues([
                    domain.OrderStatus.paid,
                    domain.OrderStatus.done,
                  ]),
            ))
            .get();
    // Voids recorded that day (kept only for orders that had been paid).
    final voided =
        await (db.select(db.orders)..where(
              (t) =>
                  t.closedAt.isBiggerOrEqualValue(from) &
                  t.closedAt.isSmallerThanValue(to) &
                  t.status.equalsValue(domain.OrderStatus.voided),
            ))
            .get();

    var gross = domain.Money.zero;
    var subtotal = domain.Money.zero;
    var tax = domain.Money.zero;
    for (final o in paid) {
      gross += o.total;
      subtotal += o.subtotal;
      tax += o.tax;
    }

    final paidIds = paid.map((o) => o.id).toList();
    return DailyReport(
      day: from,
      ordersPaid: paid.length,
      ordersVoided: voided.length,
      gross: gross,
      subtotal: subtotal,
      tax: tax,
      comps: await _comps(paidIds),
      collected: await _collected(from, to),
      itemSales: await _itemSales(paidIds),
    );
  }

  /// Total worth of comped (on-the-house) lines across the day's paid orders.
  Future<domain.Money> _comps(List<String> paidOrderIds) async {
    if (paidOrderIds.isEmpty) return domain.Money.zero;
    final lines =
        await (db.select(db.orderLines)..where(
              (t) =>
                  t.orderId.isIn(paidOrderIds) &
                  t.status.equalsValue(domain.OrderLineStatus.active) &
                  t.comped.equals(true),
            ))
            .get();
    return lines.fold<domain.Money>(
      domain.Money.zero,
      (s, l) => s + l.lineTotal,
    );
  }

  /// [dailyReport], recomputed whenever orders, lines or payments
  /// change — keeps the screen live while the restaurant operates.
  Stream<DailyReport> watchDailyReport(DateTime day) {
    return db
        .customSelect(
          'SELECT 1',
          readsFrom: {db.orders, db.orderLines, db.payments},
        )
        .watch()
        .asyncMap((_) => dailyReport(day));
  }

  /// Finished (`done`) and `voided` orders of that day, newest first — the
  /// history browser. (A `paid` order is still on the board, not here yet.)
  Stream<List<domain.Order>> watchClosedOrders(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    final q = db.select(db.orders)
      ..where(
        (t) =>
            t.closedAt.isBiggerOrEqualValue(from) &
            t.closedAt.isSmallerThanValue(to) &
            t.status.isInValues([
              domain.OrderStatus.done,
              domain.OrderStatus.voided,
            ]),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.closedAt)]);
    return q.watch().map(
      (rows) => rows
          .map(
            (r) => domain.Order(
              id: r.id,
              type: r.type,
              status: r.status,
              tableId: r.tableId,
              createdAt: r.createdAt,
              paidAt: r.paidAt,
              closedAt: r.closedAt,
              taxRateBp: r.taxRateBp,
              subtotal: r.subtotal,
              tax: r.tax,
              total: r.total,
              note: r.note,
            ),
          )
          .toList(),
    );
  }

  // --- Internals ---

  Future<List<MethodTotals>> _collected(DateTime from, DateTime to) async {
    final rows =
        await (db.select(db.payments)..where(
              (t) =>
                  t.createdAt.isBiggerOrEqualValue(from) &
                  t.createdAt.isSmallerThanValue(to) &
                  t.status.equalsValue(domain.PaymentStatus.approved),
            ))
            .get();
    final byMethod = <domain.PaymentMethod, List<PaymentRow>>{};
    for (final r in rows) {
      byMethod.putIfAbsent(r.method, () => []).add(r);
    }
    return [
      for (final method in domain.PaymentMethod.values)
        if (byMethod.containsKey(method))
          MethodTotals(
            method: method,
            count: byMethod[method]!.length,
            amount: byMethod[method]!.fold<domain.Money>(
              domain.Money.zero,
              (s, r) => s + r.amount,
            ),
            tips: byMethod[method]!.fold<domain.Money>(
              domain.Money.zero,
              (s, r) => s + r.tip,
            ),
          ),
    ];
  }

  Future<List<ItemSales>> _itemSales(List<String> paidOrderIds) async {
    if (paidOrderIds.isEmpty) return const [];
    final lines =
        await (db.select(db.orderLines)..where(
              (t) =>
                  t.orderId.isIn(paidOrderIds) &
                  t.status.equalsValue(domain.OrderLineStatus.active),
            ))
            .get();
    final byName = <String, ({int qty, domain.Money revenue})>{};
    for (final l in lines) {
      final cur =
          byName[l.nameSnapshot] ?? (qty: 0, revenue: domain.Money.zero);
      byName[l.nameSnapshot] = (
        qty: cur.qty + l.qty,
        // A comped line still counts as sold (qty) but earned nothing.
        revenue: cur.revenue + (l.comped ? domain.Money.zero : l.lineTotal),
      );
    }
    final result = [
      for (final e in byName.entries)
        ItemSales(name: e.key, qty: e.value.qty, revenue: e.value.revenue),
    ]..sort((a, b) => b.qty.compareTo(a.qty));
    return result;
  }
}
