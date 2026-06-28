import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/sync_harness.dart';

void main() {
  test(
    'pendingPush labels each change (a delete by its prior name) and a '
    'selective push uploads only the chosen ones, holding the rest',
    () async {
      final clock = TickingClock();
      final cloud = FakeCloud();
      final a = await makeDevice(
        clock,
        'A',
        buildBackend: () => FakeCloudBackend(cloud, 'A'),
      );
      final b = await makeDevice(
        clock,
        'B',
        buildBackend: () => FakeCloudBackend(cloud, 'B'),
      );
      addTearDown(a.db.close);
      addTearDown(b.db.close);

      final cat = Category(id: newId(), name: 'Mains');
      await a.menu.upsertCategory(cat);
      final tea = MenuItem(
        id: newId(),
        categoryId: cat.id,
        name: 'Tea',
        price: const Money(300),
      );
      final cola = MenuItem(
        id: newId(),
        categoryId: cat.id,
        name: 'Cola',
        price: const Money(250),
      );
      await a.menu.upsertItem(tea);
      await a.menu.upsertItem(cola);
      await a.sync.syncNow(); // push everything; bring B in sync
      await b.sync.syncNow();
      expect(
        (await b.menu.watchItemsInCategory(cat.id).first).map((i) => i.name),
        containsAll(['Tea', 'Cola']),
      );

      // A: rename Tea, delete Cola — two pending changes.
      await a.menu.upsertItem(
        MenuItem(
          id: tea.id,
          categoryId: cat.id,
          name: 'Green Tea',
          price: const Money(300),
        ),
      );
      await a.menu.deleteItem(cola.id);

      final pending = await a.sync.pendingPush();
      expect(pending.total, 2);
      expect(pending.deletes, 1);
      final rename = pending.changes.firstWhere(
        (c) => !c.isDelete && c.entityId == tea.id,
      );
      final delete = pending.changes.firstWhere(
        (c) => c.isDelete && c.entityId == cola.id,
      );
      expect(
        rename.name,
        'Green Tea',
        reason: 'upsert labelled by its payload',
      );
      expect(
        delete.name,
        'Cola',
        reason: 'delete labelled by its prior payload',
      );

      // Push ONLY the rename; hold back the delete.
      await a.sync.syncNow(pushIds: {rename.id});
      await b.sync.syncNow();

      final bItems = await b.menu.watchItemsInCategory(cat.id).first;
      expect(
        bItems.map((i) => i.name),
        containsAll(['Green Tea', 'Cola']),
        reason: 'the rename synced; the held-back delete did not',
      );
      expect(bItems.any((i) => i.name == 'Tea'), isFalse);

      // The unselected delete is still pending on A (nothing discarded).
      final after = await a.sync.pendingPush();
      expect(
        after.changes.map((c) => c.entityId),
        [cola.id],
        reason: 'only the held-back delete remains',
      );
    },
  );
}
