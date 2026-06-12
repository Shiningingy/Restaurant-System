import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late MenuRepository menu;
  late OrderRepository orders;

  late MenuItem burger; // $10.00, with Size group
  late MenuItem fries; //  $3.50, no modifiers
  late Modifier sizeLarge; // +$2.00

  setUp(() async {
    db = createTestDb();
    menu = MenuRepository(db);
    orders = OrderRepository(db);

    final cat = Category(id: newId(), name: 'Mains');
    await menu.upsertCategory(cat);

    final sizeGroup = ModifierGroup(
      id: newId(),
      name: 'Size',
      minSelect: 1,
      maxSelect: 1,
    );
    await menu.upsertModifierGroup(sizeGroup);
    sizeLarge = Modifier(
      id: newId(),
      groupId: sizeGroup.id,
      name: 'Large',
      priceDelta: const Money(200),
    );
    await menu.upsertModifier(sizeLarge);

    burger = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Burger',
      price: const Money(1000),
      modifierGroupIds: [sizeGroup.id],
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

  test(
    'take and close an order fully offline (Phase 1 exit criterion)',
    () async {
      final orderId = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 1300,
      );

      // Burger (Large +$2.00) and 2x fries.
      await orders.addLine(
        orderId: orderId,
        item: burger,
        selectedModifiers: [sizeLarge],
      );
      await orders.addLine(orderId: orderId, item: fries, qty: 2);

      // Subtotal 12.00 + 7.00 = 19.00; 13% tax = 2.47; total 21.47.
      var order = (await orders.watchOrder(orderId).first)!;
      expect(order.subtotal, const Money(1900));
      expect(order.tax, const Money(247));
      expect(order.total, const Money(2147));

      await orders.closeOrder(orderId: orderId, method: PaymentMethod.cash);

      order = (await orders.watchOrder(orderId).first)!;
      expect(order.status, OrderStatus.paid);
      expect(order.closedAt, isNotNull);

      final payments = await db.select(db.payments).get();
      expect(payments, hasLength(1));
      expect(payments.single.amount, const Money(2147));
      expect(payments.single.status, PaymentStatus.approved);

      // Closed order no longer shows as open.
      expect(await orders.watchOpenOrders().first, isEmpty);
    },
  );

  test('line modifiers are snapshotted with name and price delta', () async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.addLine(
      orderId: orderId,
      item: burger,
      selectedModifiers: [sizeLarge],
    );

    final lines = await orders.watchLines(orderId).first;
    expect(lines.single.lineTotal, const Money(1200));
    expect(lines.single.modifiers.single.nameSnapshot, 'Large');
    expect(lines.single.modifiers.single.priceDeltaSnapshot, const Money(200));
  });

  test(
    'qty change recomputes line and order totals including modifiers',
    () async {
      final orderId = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      await orders.addLine(
        orderId: orderId,
        item: burger,
        selectedModifiers: [sizeLarge],
      );

      final line = (await orders.watchLines(orderId).first).single;
      await orders.setLineQty(line.id, 3);

      final updated = (await orders.watchLines(orderId).first).single;
      expect(updated.lineTotal, const Money(3600)); // (10.00 + 2.00) * 3

      final order = (await orders.watchOrder(orderId).first)!;
      expect(order.total, const Money(3600));
    },
  );

  test('voiding a line keeps the row but removes it from totals', () async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.addLine(orderId: orderId, item: fries);
    await orders.addLine(orderId: orderId, item: burger);

    final friesLine = (await orders.watchLines(orderId).first).firstWhere(
      (l) => l.nameSnapshot == 'Fries',
    );
    await orders.voidLine(friesLine.id);

    final lines = await orders.watchLines(orderId).first;
    expect(lines, hasLength(2)); // status flip, never a delete
    expect(
      lines.firstWhere((l) => l.id == friesLine.id).status,
      OrderLineStatus.voided,
    );

    final order = (await orders.watchOrder(orderId).first)!;
    expect(order.subtotal, const Money(1000)); // burger only
  });

  test('menu edits never rewrite order history (price snapshot)', () async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 0,
    );
    await orders.addLine(orderId: orderId, item: fries);
    await orders.closeOrder(orderId: orderId, method: PaymentMethod.cash);

    // Double the menu price afterwards.
    await menu.upsertItem(fries.copyWith(price: const Money(700)));

    final order = (await orders.watchOrder(orderId).first)!;
    expect(order.total, const Money(350)); // unchanged
    final line = (await orders.watchLines(orderId).first).single;
    expect(line.priceSnapshot, const Money(350));
  });

  test('orders snapshot the tax rate at creation', () async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 500,
    );
    await orders.addLine(orderId: orderId, item: fries); // 3.50 @ 5% = 0.18 tax

    final order = (await orders.watchOrder(orderId).first)!;
    expect(order.taxRateBp, 500);
    expect(order.tax, const Money(18));
  });
}
