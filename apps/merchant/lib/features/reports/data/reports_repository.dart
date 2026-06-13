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

    final closed =
        await (db.select(db.orders)..where(
              (t) =>
                  t.closedAt.isBiggerOrEqualValue(from) &
                  t.closedAt.isSmallerThanValue(to),
            ))
            .get();
    final paid = closed
        .where((o) => o.status == domain.OrderStatus.paid)
        .toList();
    final voided = closed
        .where((o) => o.status == domain.OrderStatus.voided)
        .length;

    var gross = domain.Money.zero;
    var subtotal = domain.Money.zero;
    var tax = domain.Money.zero;
    for (final o in paid) {
      gross += o.total;
      subtotal += o.subtotal;
      tax += o.tax;
    }

    return DailyReport(
      day: from,
      ordersPaid: paid.length,
      ordersVoided: voided,
      gross: gross,
      subtotal: subtotal,
      tax: tax,
      collected: await _collected(from, to),
      itemSales: await _itemSales(paid.map((o) => o.id).toList()),
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

  /// Closed orders (paid and voided) of that day, newest first — the
  /// history browser.
  Stream<List<domain.Order>> watchClosedOrders(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    final q = db.select(db.orders)
      ..where(
        (t) =>
            t.closedAt.isBiggerOrEqualValue(from) &
            t.closedAt.isSmallerThanValue(to) &
            t.status.isInValues([
              domain.OrderStatus.paid,
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
        revenue: cur.revenue + l.lineTotal,
      );
    }
    final result = [
      for (final e in byName.entries)
        ItemSales(name: e.key, qty: e.value.qty, revenue: e.value.revenue),
    ]..sort((a, b) => b.qty.compareTo(a.qty));
    return result;
  }
}
