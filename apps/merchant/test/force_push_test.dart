import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/sync_harness.dart';

/// Force push ("make the cloud match this device") is the recovery for the
/// real incident: a second device pushed a sample menu over the cloud and the
/// good data survived only on the first device.
void main() {
  late FakeCloud cloud;
  late TickingClock clock;

  setUp(() {
    cloud = FakeCloud();
    clock = TickingClock();
  });

  test('force push restores this device over a cloud another device wiped '
      'and removes that device\'s stray rows', () async {
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

    // A (the desktop) has the real menu and pushed it to the cloud.
    final cat = Category(id: newId(), name: 'Mains');
    await a.menu.upsertCategory(cat);
    final real = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Real Dish',
      price: const Money(1200),
    );
    await a.menu.upsertItem(real);
    await a.sync.syncNow();

    // B (the laptop) pulled the menu, then pushed a sample item and deleted the
    // real dish — overwriting the cloud. A never syncs again, so it keeps truth.
    await b.sync.syncNow();
    final sample = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Sample',
      price: const Money(1),
    );
    await b.menu.upsertItem(sample);
    await b.menu.deleteItem(real.id);
    await b.sync.syncNow();

    // Recovery: A pushes its truth back over the cloud.
    final outcome = await a.sync.forcePushFromThisDevice();
    expect(outcome.ok, isTrue);
    expect(outcome.pushed, greaterThan(0));

    // B syncs and converges to A: the real dish is back, the sample is gone.
    await b.sync.syncNow();
    final bItems = await b.menu.watchItemsInCategory(cat.id).first;
    expect(bItems.map((i) => i.name), ['Real Dish']);
    expect(await b.db.select(b.db.menuItems).get(), hasLength(1));

    // A itself was never modified by the recovery.
    final aItems = await a.menu.watchItemsInCategory(cat.id).first;
    expect(aItems.map((i) => i.name), ['Real Dish']);
  });

  test('force push does not delete a cloud row this device also has', () async {
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

    // Both devices share a category and a "Keep" item; B re-saved it last, so
    // the cloud's latest "Keep" row is attributed to device B.
    final cat = Category(id: newId(), name: 'Mains');
    await a.menu.upsertCategory(cat);
    final keep = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Keep',
      price: const Money(500),
    );
    await a.menu.upsertItem(keep);
    await a.sync.syncNow();
    await b.sync.syncNow();
    await b.menu.upsertItem(keep.copyWith(name: 'Keep edited on B'));
    await b.sync.syncNow();

    // A force-pushes. "Keep" is alive on the cloud from B and present on A, so
    // it must NOT be deleted — only re-asserted as A's version.
    await a.sync.forcePushFromThisDevice();
    await b.sync.syncNow();

    final bItems = await b.menu.watchItemsInCategory(cat.id).first;
    expect(bItems.map((i) => i.name), [
      'Keep',
    ]); // A's version wins, not deleted
    expect(await b.db.select(b.db.menuItems).get(), hasLength(1));
  });

  test('a backup is taken before a sync touches the database', () async {
    final reasons = <String>[];
    final a = await makeDevice(
      clock,
      'A',
      buildBackend: () => FakeCloudBackend(cloud, 'A'),
      snapshot: (reason) async => reasons.add(reason),
    );
    addTearDown(a.db.close);

    await a.menu.upsertCategory(Category(id: newId(), name: 'Mains'));
    await a.sync.syncNow();
    await a.sync.restoreFromCloud();
    await a.sync.forcePushFromThisDevice();

    expect(reasons, ['sync', 'restore', 'forcepush']);
  });

  test('force push is a no-op when the cloud is not configured', () async {
    final a = await makeDevice(
      clock,
      'A',
      buildBackend: () => FakeCloudBackend(cloud, 'A'),
      configured: false,
    );
    addTearDown(a.db.close);
    final outcome = await a.sync.forcePushFromThisDevice();
    expect(outcome.ok, isFalse);
  });
}
