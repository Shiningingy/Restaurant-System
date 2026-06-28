import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/payments/data/payment_repository.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late MenuRepository menu;
  late OrderRepository orders;
  late PaymentRepository payments;

  late MenuItem burger; // $10.00, with Size group
  late MenuItem fries; //  $3.50, no modifiers
  late Modifier sizeLarge; // +$2.00

  setUp(() async {
    db = createTestDb();
    menu = MenuRepository(db);
    orders = OrderRepository(db);
    payments = PaymentRepository(db);

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

      final closed = await payments.recordApproved(
        orderId: orderId,
        method: PaymentMethod.cash,
        amount: const Money(2147),
      );
      expect(closed, isTrue);

      order = (await orders.watchOrder(orderId).first)!;
      expect(order.status, OrderStatus.paid);
      expect(order.paidAt, isNotNull);
      expect(order.closedAt, isNull);

      final rows = await db.select(db.payments).get();
      expect(rows, hasLength(1));
      expect(rows.single.amount, const Money(2147));
      expect(rows.single.status, PaymentStatus.approved);

      // A paid order stays on the board (Pending) until it's finished.
      expect(await orders.watchOpenOrders().first, hasLength(1));
      await orders.markFinished(orderId);
      final done = (await orders.watchOrder(orderId).first)!;
      expect(done.status, OrderStatus.done);
      expect(done.closedAt, isNotNull);
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

  test('deleteOrder removes the order, its lines and payments', () async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.addLine(
      orderId: orderId,
      item: burger,
      selectedModifiers: [sizeLarge],
    );
    await orders.addLine(orderId: orderId, item: fries);
    final order = (await orders.watchOrder(orderId).first)!;
    await payments.recordApproved(
      orderId: orderId,
      method: PaymentMethod.cash,
      amount: order.total,
    );

    await orders.deleteOrder(orderId);

    expect(await orders.watchOrder(orderId).first, isNull);
    expect(await orders.watchLines(orderId).first, isEmpty);
    expect(
      await (db.select(
        db.payments,
      )..where((t) => t.orderId.equals(orderId))).get(),
      isEmpty,
    );
  });

  test('menu edits never rewrite order history (price snapshot)', () async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 0,
    );
    await orders.addLine(orderId: orderId, item: fries);
    await payments.recordApproved(
      orderId: orderId,
      method: PaymentMethod.cash,
      amount: const Money(350),
    );

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

  group('adding the same item merges into one line', () {
    test(
      'identical item + modifiers stacks qty instead of duplicating',
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
        await orders.addLine(
          orderId: orderId,
          item: burger,
          selectedModifiers: [sizeLarge],
        );

        final lines = await orders.watchLines(orderId).first;
        expect(lines, hasLength(1));
        expect(lines.single.qty, 2);
        expect(lines.single.lineTotal, const Money(2400)); // (10.00 + 2.00) * 2

        final order = (await orders.watchOrder(orderId).first)!;
        expect(order.subtotal, const Money(2400));
      },
    );

    test('quantities accumulate across adds', () async {
      final orderId = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      await orders.addLine(orderId: orderId, item: fries, qty: 2);
      await orders.addLine(orderId: orderId, item: fries);

      final lines = await orders.watchLines(orderId).first;
      expect(lines, hasLength(1));
      expect(lines.single.qty, 3);
      expect(lines.single.lineTotal, const Money(1050)); // 3.50 * 3
    });

    test('a different note keeps the lines separate', () async {
      final orderId = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      await orders.addLine(orderId: orderId, item: fries, note: 'crispy');
      await orders.addLine(orderId: orderId, item: fries, note: 'soft');

      final lines = await orders.watchLines(orderId).first;
      expect(lines, hasLength(2));
    });

    test(
      'a voided line is not reused — a re-add starts a fresh line',
      () async {
        final orderId = await orders.createOrder(
          type: OrderType.takeout,
          taxRateBp: 0,
        );
        await orders.addLine(orderId: orderId, item: fries);
        final first = (await orders.watchLines(orderId).first).single;
        await orders.voidLine(first.id);

        await orders.addLine(orderId: orderId, item: fries);

        final lines = await orders.watchLines(orderId).first;
        expect(lines, hasLength(2)); // one voided, one fresh active
        final active = lines
            .where((l) => l.status == OrderLineStatus.active)
            .toList();
        expect(active, hasLength(1));
        expect(active.single.qty, 1);
      },
    );
  });

  group('discount and service fee', () {
    test('service fee is snapshotted and charged; discount comes off before '
        'tax', () async {
      final orderId = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 1300,
        serviceFeeBp: 1000, // 10%
      );
      await orders.addLine(orderId: orderId, item: fries, qty: 2); // $7.00

      var order = (await orders.watchOrder(orderId).first)!;
      // 7.00 + 10% fee (0.70) + 13% tax (0.91) = 8.61
      expect(order.subtotal, const Money(700));
      expect(order.serviceFee, const Money(70));
      expect(order.tax, const Money(91));
      expect(order.total, const Money(861));

      await orders.setDiscount(orderId, const Money(100)); // $1.00 off
      order = (await orders.watchOrder(orderId).first)!;
      // discounted 6.00 -> fee 0.60, tax 0.78, total 7.38
      expect(order.discount, const Money(100));
      expect(order.serviceFee, const Money(60));
      expect(order.tax, const Money(78));
      expect(order.total, const Money(738));
    });
  });

  group('void & discard', () {
    test('voiding an unpaid order discards it; a paid void is kept', () async {
      // Unpaid void → gone (a misclick shouldn't clutter history).
      final unpaid = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      await orders.addLine(orderId: unpaid, item: burger);
      await orders.voidOrder(unpaid);
      expect(await orders.getOrder(unpaid), isNull);

      // Paid void → kept as a voided record.
      final paid = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      await orders.addLine(orderId: paid, item: burger);
      await payments.recordApproved(
        orderId: paid,
        method: PaymentMethod.cash,
        amount: const Money(1000),
      );
      await orders.voidOrder(paid);
      final voided = (await orders.getOrder(paid))!;
      expect(voided.status, OrderStatus.voided);
      expect(voided.closedAt, isNotNull);
    });

    test('discardIfEmpty removes empty unpaid orders only', () async {
      // Opened, nothing added → discarded.
      final empty = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      expect(await orders.discardIfEmpty(empty), isTrue);
      expect(await orders.getOrder(empty), isNull);

      // Every line voided → also empty → discarded.
      final emptied = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      await orders.addLine(orderId: emptied, item: burger);
      final line = (await orders.getLines(emptied)).single;
      await orders.voidLine(line.id);
      expect(await orders.discardIfEmpty(emptied), isTrue);
      expect(await orders.getOrder(emptied), isNull);

      // Has an active line → kept.
      final withItem = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      await orders.addLine(orderId: withItem, item: fries);
      expect(await orders.discardIfEmpty(withItem), isFalse);
      expect(await orders.getOrder(withItem), isNotNull);
    });
  });

  group('comps (free items)', () {
    test('setLineComped frees a line: out of the total, worth kept', () async {
      final orderId = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 1300,
      );
      await orders.addLine(orderId: orderId, item: burger); // $10.00
      await orders.addLine(orderId: orderId, item: fries); //  $3.50

      final friesLine = (await orders.watchLines(orderId).first).firstWhere(
        (l) => l.nameSnapshot == 'Fries',
      );
      await orders.setLineComped(friesLine.id, true);

      final fl = (await orders.watchLines(orderId).first).firstWhere(
        (l) => l.id == friesLine.id,
      );
      expect(fl.comped, isTrue);
      expect(fl.lineTotal, const Money(350)); // worth preserved
      expect(fl.status, OrderLineStatus.active); // still made & on the receipt

      final order = (await orders.watchOrder(orderId).first)!;
      // Only the burger bills: subtotal 10.00, 13% tax 1.30, total 11.30.
      expect(order.subtotal, const Money(1000));
      expect(order.tax, const Money(130));
      expect(order.total, const Money(1130));

      // Un-comp restores it to the bill.
      await orders.setLineComped(friesLine.id, false);
      expect(
        (await orders.watchOrder(orderId).first)!.subtotal,
        const Money(1350),
      );
    });

    test('addFreeItem adds a comped line that never bills or stacks', () async {
      final orderId = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      await orders.addLine(orderId: orderId, item: fries); // paid $3.50
      await orders.addFreeItem(orderId: orderId, item: fries); // free

      final lines = await orders.watchLines(orderId).first;
      // A giveaway never merges with the paid line of the same item.
      expect(lines, hasLength(2));
      expect(lines.firstWhere((l) => l.comped).lineTotal, const Money(350));

      final order = (await orders.watchOrder(orderId).first)!;
      expect(order.subtotal, const Money(350)); // only the paid fries
      expect(order.total, const Money(350));
    });

    test('a new paid add never stacks onto a comped line', () async {
      final orderId = await orders.createOrder(
        type: OrderType.takeout,
        taxRateBp: 0,
      );
      await orders.addFreeItem(orderId: orderId, item: fries); // free
      await orders.addLine(orderId: orderId, item: fries); // paid

      final lines = await orders.watchLines(orderId).first;
      expect(lines, hasLength(2));
      expect(lines.where((l) => l.comped), hasLength(1));
      expect(lines.where((l) => !l.comped), hasLength(1));

      expect(
        (await orders.watchOrder(orderId).first)!.subtotal,
        const Money(350), // only the paid one
      );
    });
  });
}
