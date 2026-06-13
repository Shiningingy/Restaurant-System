import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/payments/data/payment_repository.dart';
import 'package:merchant/features/reports/data/reports_repository.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late OrderRepository orders;
  late PaymentRepository payments;
  late ReportsRepository reports;

  late MenuItem burger; // $10.00
  late MenuItem fries; //  $3.50

  setUp(() async {
    db = createTestDb();
    orders = OrderRepository(db);
    payments = PaymentRepository(db);
    reports = ReportsRepository(db);

    final menu = MenuRepository(db);
    final cat = Category(id: newId(), name: 'Mains');
    await menu.upsertCategory(cat);
    burger = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Burger',
      price: const Money(1000),
    );
    fries = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Fries',
      price: const Money(350),
    );
    await menu.upsertItem(burger);
    await menu.upsertItem(fries);
  });

  tearDown(() => db.close());

  /// Creates a paid order at 13% tax and returns its id.
  Future<String> paidOrder(
    List<(MenuItem, int)> items, {
    PaymentMethod method = PaymentMethod.cash,
    Money tip = Money.zero,
  }) async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    for (final (item, qty) in items) {
      await orders.addLine(orderId: orderId, item: item, qty: qty);
    }
    final order = (await orders.getOrder(orderId))!;
    await payments.recordApproved(
      orderId: orderId,
      method: method,
      amount: order.total,
      tip: tip,
    );
    return orderId;
  }

  /// Moves an order's close time (and its payments) to another day, to
  /// simulate history.
  Future<void> backdate(String orderId, DateTime to) async {
    await (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(closedAt: Value(to)),
    );
    await (db.update(db.payments)..where((t) => t.orderId.equals(orderId)))
        .write(PaymentsCompanion(createdAt: Value(to)));
  }

  test('end-of-day report matches the day\'s closed orders '
      '(Phase 4 exit criterion)', () async {
    // Today: burger order paid cash with a $2 tip ($11.30),
    // 2x fries order paid by card ($7.91), one voided order,
    // one still-open order. Yesterday: a burger order.
    await paidOrder([(burger, 1)], tip: const Money(200));
    await paidOrder([(fries, 2)], method: PaymentMethod.manual);

    final voidedId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.addLine(orderId: voidedId, item: burger);
    await orders.voidOrder(voidedId);

    final openId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.addLine(orderId: openId, item: burger);

    final yesterdayId = await paidOrder([(burger, 1)]);
    await backdate(
      yesterdayId,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    final report = await reports.dailyReport(DateTime.now());

    // Sales side: the two orders paid today only.
    expect(report.ordersPaid, 2);
    expect(report.ordersVoided, 1);
    expect(report.gross, const Money(1130 + 791));
    expect(report.subtotal, const Money(1000 + 700));
    expect(report.tax, const Money(130 + 91));

    // Drawer side: cash $11.30 + $2.00 tip, card $7.91.
    final cash = report.collected.singleWhere(
      (m) => m.method == PaymentMethod.cash,
    );
    final card = report.collected.singleWhere(
      (m) => m.method == PaymentMethod.manual,
    );
    expect(cash.count, 1);
    expect(cash.amount, const Money(1130));
    expect(cash.tips, const Money(200));
    expect(card.amount, const Money(791));
    expect(report.collectedTotal, const Money(1130 + 791));
    expect(report.tipsTotal, const Money(200));

    // Item counts: voided/open/yesterday orders contribute nothing.
    expect(report.itemSales, hasLength(2));
    final friesSales = report.itemSales.singleWhere((i) => i.name == 'Fries');
    expect(friesSales.qty, 2);
    expect(friesSales.revenue, const Money(700));
    final burgerSales = report.itemSales.singleWhere((i) => i.name == 'Burger');
    expect(burgerSales.qty, 1);
  });

  test('declined payments never reach the drawer', () async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.addLine(orderId: orderId, item: burger);
    await payments.recordDeclined(
      orderId: orderId,
      method: PaymentMethod.manual,
      amount: const Money(1130),
    );

    final report = await reports.dailyReport(DateTime.now());
    expect(report.collected, isEmpty);
    expect(report.ordersPaid, 0);
  });

  test('voided line in a paid order is excluded from item sales', () async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 0,
    );
    await orders.addLine(orderId: orderId, item: burger);
    await orders.addLine(orderId: orderId, item: fries);
    final friesLine = (await orders.getLines(
      orderId,
    )).firstWhere((l) => l.nameSnapshot == 'Fries');
    await orders.voidLine(friesLine.id);
    await payments.recordApproved(
      orderId: orderId,
      method: PaymentMethod.cash,
      amount: const Money(1000),
    );

    final report = await reports.dailyReport(DateTime.now());
    expect(report.itemSales.map((i) => i.name), ['Burger']);
    expect(report.gross, const Money(1000));
  });

  test('history lists the day\'s paid and voided orders, newest first, '
      'open orders excluded', () async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final paidId = await paidOrder([(burger, 1)]);
    final voidedId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.voidOrder(voidedId);
    // Drift stores DateTime at second precision; pin distinct close
    // times (inside today) so "newest first" is deterministic.
    await backdate(paidId, todayStart.add(const Duration(minutes: 1)));
    await backdate(voidedId, todayStart.add(const Duration(minutes: 2)));
    await orders.createOrder(type: OrderType.takeout, taxRateBp: 1300);

    final yesterdayId = await paidOrder([(fries, 1)]);
    await backdate(
      yesterdayId,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    final today = await reports.watchClosedOrders(DateTime.now()).first;
    expect(today.map((o) => o.id), containsAll([paidId, voidedId]));
    expect(today, hasLength(2));
    expect(today.first.id, voidedId); // closed last

    final yesterday = await reports
        .watchClosedOrders(DateTime.now().subtract(const Duration(days: 1)))
        .first;
    expect(yesterday.map((o) => o.id), [yesterdayId]);
  });
}
