import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/payments/data/payment_repository.dart';
import 'package:merchant/core/sync/sync_codec.dart';
import 'package:merchant/core/sync/sync_journal.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late SyncJournal journal;
  late MenuRepository menu;
  late OrderRepository orders;
  late PaymentRepository payments;

  setUp(() {
    db = createTestDb();
    journal = SyncJournal(db);
    menu = MenuRepository(db, journal: journal);
    orders = OrderRepository(db, journal: journal);
    payments = PaymentRepository(db, journal: journal);
  });

  tearDown(() => db.close());

  test('every mutated entity is journaled as an unsynced change', () async {
    final cat = Category(id: newId(), name: 'Mains');
    await menu.upsertCategory(cat);
    final burger = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Burger',
      price: const Money(1000),
    );
    await menu.upsertItem(burger);

    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.addLine(orderId: orderId, item: burger);
    await payments.recordApproved(
      orderId: orderId,
      method: PaymentMethod.cash,
      amount: const Money(1130),
    );

    final entries = await journal.unsynced();
    final entities = entries.map((e) => e.entity).toSet();
    expect(
      entities,
      containsAll([
        SyncEntities.category,
        SyncEntities.menuItem,
        SyncEntities.order,
        SyncEntities.payment,
      ]),
    );
    // All start unsynced.
    expect(entries.every((e) => e.syncedAt == null), isTrue);
  });

  test('journal entries carry the full row payload and strictly '
      'increasing timestamps', () async {
    final cat = Category(id: newId(), name: 'Drinks');
    await menu.upsertCategory(cat);
    final entry = (await journal.unsynced()).single;
    expect(entry.op, SyncOp.update);
    final payload = jsonDecode(entry.payload!) as Map<String, dynamic>;
    expect(payload['name'], 'Drinks');

    await menu.upsertCategory(cat); // touch it again
    final times = (await journal.unsynced())
        .map((e) => e.occurredAtUs)
        .toList();
    expect(times[1] > times[0], isTrue);
  });

  test('markSynced clears entries from the unsynced set', () async {
    await menu.upsertCategory(Category(id: newId(), name: 'X'));
    final before = await journal.unsynced();
    expect(before, isNotEmpty);
    await journal.markSynced(before.map((e) => e.id).toList(), DateTime(2026));
    expect(await journal.unsynced(), isEmpty);
  });

  test('hard-deleting a modifier journals a delete op', () async {
    final group = ModifierGroup(id: newId(), name: 'Size');
    await menu.upsertModifierGroup(group);
    final mod = Modifier(
      id: newId(),
      groupId: group.id,
      name: 'Large',
      priceDelta: const Money(200),
    );
    await menu.upsertModifier(mod);
    await menu.deleteModifier(mod.id);

    final deletes = (await journal.unsynced())
        .where((e) => e.op == SyncOp.delete)
        .toList();
    expect(deletes.single.entity, SyncEntities.modifier);
    expect(deletes.single.entityId, mod.id);
  });
}
