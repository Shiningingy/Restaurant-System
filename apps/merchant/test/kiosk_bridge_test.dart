import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/customer_display/application/kiosk_bridge.dart';
import 'package:merchant/features/customer_display/presentation/kiosk_menu.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import 'helpers/test_db.dart';

void main() {
  group('kiosk menu snapshot', () {
    late final db = createTestDb();
    final menu = MenuRepository(db);

    setUpAll(() async {
      await menu.upsertCategory(
        const domain.Category(id: 'c1', name: 'Drinks', sortOrder: 0),
      );
      // An empty category should be omitted from the snapshot.
      await menu.upsertCategory(
        const domain.Category(id: 'c2', name: 'Empty', sortOrder: 1),
      );
      await menu.upsertModifierGroup(
        const domain.ModifierGroup(
          id: 'g1',
          name: 'Size',
          minSelect: 1,
          maxSelect: 1,
        ),
      );
      await menu.upsertModifier(
        const domain.Modifier(
          id: 'm1',
          groupId: 'g1',
          name: 'Large',
          priceDelta: domain.Money(50),
        ),
      );
      await menu.upsertItem(
        const domain.MenuItem(
          id: 'i1',
          categoryId: 'c1',
          name: 'Cola',
          price: domain.Money(250),
          modifierGroupIds: ['g1'],
        ),
      );
      // Inactive items are excluded.
      await menu.upsertItem(
        const domain.MenuItem(
          id: 'i2',
          categoryId: 'c1',
          name: 'Hidden',
          price: domain.Money(100),
          isActive: false,
        ),
      );
    });

    tearDownAll(() => db.close());

    test(
      'serializes active items with prices and modifiers, omits empties',
      () async {
        final snap = await buildKioskMenuSnapshot(
          menu,
          businessName: 'Joe Cafe',
          taxRateBp: 1300,
          serviceFeeBp: 250,
          payHere: true,
        );
        expect(snap['businessName'], 'Joe Cafe');

        // Round-trips through the kiosk-side parser the sub-window uses.
        final parsed = KioskMenu.fromJson(snap);
        expect(parsed.taxRateBp, 1300);
        expect(parsed.serviceFeeBp, 250);
        expect(parsed.payHere, isTrue);
        expect(parsed.categories.map((c) => c.name), [
          'Drinks',
        ]); // Empty omitted

        final items = parsed.categories.single.items;
        expect(items.map((i) => i.name), ['Cola']); // Hidden excluded

        final cola = items.single;
        expect(cola.priceCents, 250);
        expect(cola.price, r'$2.50');
        expect(cola.modifierGroups.single.name, 'Size');
        expect(cola.modifierGroups.single.isSingleChoice, isTrue);
        expect(cola.modifierGroups.single.isRequired, isTrue);
        expect(cola.modifierGroups.single.modifiers.single.deltaCents, 50);
      },
    );
  });

  group('registerKioskOrder', () {
    late AppDatabase db;
    late MenuRepository menu;
    late OrderRepository orders;

    setUp(() async {
      db = createTestDb();
      menu = MenuRepository(db);
      orders = OrderRepository(db);
      await menu.upsertCategory(
        const domain.Category(id: 'c1', name: 'Mains', sortOrder: 0),
      );
      await menu.upsertModifierGroup(
        const domain.ModifierGroup(id: 'g1', name: 'Extras', maxSelect: 0),
      );
      await menu.upsertModifier(
        const domain.Modifier(
          id: 'm1',
          groupId: 'g1',
          name: 'Cheese',
          priceDelta: domain.Money(100),
        ),
      );
      await menu.upsertItem(
        const domain.MenuItem(
          id: 'i1',
          categoryId: 'c1',
          name: 'Burger',
          price: domain.Money(800),
          modifierGroupIds: ['g1'],
        ),
      );
    });

    tearDown(() => db.close());

    test(
      'creates a takeout order from a cart, applying menu prices + modifiers',
      () async {
        final res = await registerKioskOrder(
          menu: menu,
          orders: orders,
          taxRateBp: 1300,
          serviceFeeBp: 0,
          pickupNumber: 42,
          lines: [
            {
              'itemId': 'i1',
              'qty': 2,
              'modifierIds': ['m1'],
            },
          ],
        );

        expect(res['ok'], isTrue);
        final orderId = res['orderId'] as String;
        expect(res['code'], 'K42');
        // The note carries the code so the board can show it (kioskPickupCode).
        expect(kioskPickupCode('Kiosk K42'), 'K42');
        expect(kioskPickupCode('a manual note'), isNull);

        final order = await orders.getOrder(orderId);
        expect(order!.type, domain.OrderType.takeout);
        expect(order.note, 'Kiosk K42');
        // 2 × ($8.00 burger + $1.00 cheese) = $18.00 subtotal.
        expect(order.subtotal, const domain.Money(1800));

        final lines = await orders.getLines(orderId);
        expect(lines.single.qty, 2);
        expect(lines.single.nameSnapshot, 'Burger');
        expect(lines.single.modifiers.single.nameSnapshot, 'Cheese');
      },
    );

    test('skips items removed since the menu was pushed', () async {
      final res = await registerKioskOrder(
        menu: menu,
        orders: orders,
        taxRateBp: 0,
        serviceFeeBp: 0,
        pickupNumber: 1,
        lines: [
          {'itemId': 'gone', 'qty': 1, 'modifierIds': <String>[]},
          {'itemId': 'i1', 'qty': 1, 'modifierIds': <String>[]},
        ],
      );
      final lines = await orders.getLines(res['orderId'] as String);
      expect(lines.single.nameSnapshot, 'Burger'); // only the surviving item
    });

    test('empty cart is rejected', () async {
      final res = await registerKioskOrder(
        menu: menu,
        orders: orders,
        taxRateBp: 0,
        serviceFeeBp: 0,
        pickupNumber: 2,
        lines: const [],
      );
      expect(res['ok'], isFalse);
    });
  });

  group('CartLine', () {
    KioskItem item(String id) => KioskItem(
      id: id,
      code: null,
      name: 'X',
      nameSecondary: null,
      description: null,
      priceCents: 500,
      price: r'$5.00',
      modifierGroups: const [],
    );
    KioskModifier mod(String id, int cents) =>
        KioskModifier(id: id, name: id, deltaCents: cents, delta: '');

    test('unit/line totals include modifier deltas', () {
      final line = CartLine(
        item: item('i1'),
        modifiers: [mod('a', 100), mod('b', 50)],
        qty: 3,
      );
      expect(line.unitCents, 650);
      expect(line.lineCents, 1950);
    });

    test('signature stacks same item+mods regardless of mod order', () {
      final a = CartLine(
        item: item('i1'),
        modifiers: [mod('a', 0), mod('b', 0)],
      );
      final b = CartLine(
        item: item('i1'),
        modifiers: [mod('b', 0), mod('a', 0)],
      );
      final c = CartLine(item: item('i1'), modifiers: [mod('a', 0)]);
      expect(a.signature, b.signature);
      expect(a.signature, isNot(c.signature));
    });

    test('formatCents matches the receipt format', () {
      expect(formatCents(0), r'$0.00');
      expect(formatCents(5), r'$0.05');
      expect(formatCents(1234), r'$12.34');
      expect(formatCents(-250), r'-$2.50');
    });
  });
}
