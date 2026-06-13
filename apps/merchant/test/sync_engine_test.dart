import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/payments/data/payment_repository.dart';
import 'package:merchant/features/reports/data/reports_repository.dart';
import 'package:merchant/features/settings/data/tables_repository.dart';
import 'package:merchant/features/sync/application/sync_service.dart';
import 'package:merchant/features/sync/data/sync_codec.dart';
import 'package:merchant/features/sync/data/sync_journal.dart';
import 'package:merchant/features/sync/data/sync_settings.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

/// A shared in-memory stand-in for the restaurant's Supabase change feed.
/// Append-only, upsert-by-id — the same contract as the real PostgREST
/// table the [SupabaseSyncBackend] talks to.
class FakeCloud {
  final List<RemoteChange> _rows = [];
  final List<String> _ids = [];
  final List<String> _devices = [];

  void upsert(String id, String device, RemoteChange change) {
    final existing = _ids.indexOf(id);
    if (existing >= 0) {
      _rows[existing] = change;
      _devices[existing] = device;
    } else {
      _ids.add(id);
      _rows.add(change);
      _devices.add(device);
    }
  }

  List<RemoteChange> since(DateTime since, String exceptDevice) {
    final out = <RemoteChange>[];
    for (var i = 0; i < _rows.length; i++) {
      if (_devices[i] != exceptDevice && _rows[i].occurredAt.isAfter(since)) {
        out.add(_rows[i]);
      }
    }
    out.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return out;
  }
}

/// Per-device view of the [FakeCloud] — skips the device's own writes,
/// exactly like the real backend filters on `device_id`.
class FakeCloudBackend implements SyncBackend {
  final FakeCloud cloud;
  final String deviceId;

  FakeCloudBackend(this.cloud, this.deviceId);

  @override
  Future<void> push(List<SyncLogEntry> changes) async {
    for (final c in changes) {
      cloud.upsert(
        c.id,
        deviceId,
        RemoteChange(
          entity: c.entity,
          entityId: c.entityId,
          op: c.op,
          payloadJson: c.payloadJson,
          occurredAt: c.createdAt,
        ),
      );
    }
  }

  @override
  Future<List<RemoteChange>> pull({required DateTime since}) async =>
      cloud.since(since, deviceId);

  @override
  Future<SyncHealth> healthCheck() async => SyncHealth.ok;
}

/// A clock that advances on every read, giving the journal a globally
/// increasing, deterministic change order across devices.
class TickingClock {
  DateTime _t = DateTime.utc(2026, 1, 1);
  DateTime now() {
    _t = _t.add(const Duration(seconds: 1));
    return _t;
  }
}

class Device {
  final AppDatabase db;
  final MenuRepository menu;
  final OrderRepository orders;
  final PaymentRepository payments;
  final TablesRepository tables;
  final ReportsRepository reports;
  final SyncService sync;

  Device({
    required this.db,
    required this.menu,
    required this.orders,
    required this.payments,
    required this.tables,
    required this.reports,
    required this.sync,
  });
}

Future<Device> makeDevice(
  FakeCloud cloud,
  TickingClock clock,
  String deviceId, {
  bool configured = true,
}) async {
  final db = createTestDb();
  final journal = SyncJournal(db, clock: clock.now);
  final settings = SyncSettings.inMemory();
  if (configured) {
    await settings.setConfig(
      const SupabaseConfig(url: 'https://x.supabase.co', anonKey: 'anon'),
    );
  }
  return Device(
    db: db,
    menu: MenuRepository(db, journal: journal),
    orders: OrderRepository(db, journal: journal),
    payments: PaymentRepository(db, journal: journal),
    tables: TablesRepository(db, journal: journal),
    reports: ReportsRepository(db),
    sync: SyncService(
      journal: journal,
      codec: SyncCodec(db),
      settings: settings,
      buildBackend: () => FakeCloudBackend(cloud, deviceId),
      clock: () => DateTime.utc(2030),
    ),
  );
}

void main() {
  late FakeCloud cloud;
  late TickingClock clock;

  setUp(() {
    cloud = FakeCloud();
    clock = TickingClock();
  });

  test('a wiped tablet restores its data from the cloud '
      '(Phase 5 exit criterion)', () async {
    final a = await makeDevice(cloud, clock, 'A');
    addTearDown(a.db.close);

    // --- Build a realistic dataset on device A ---
    final cat = Category(id: newId(), name: 'Mains');
    await a.menu.upsertCategory(cat);
    final size = ModifierGroup(
      id: newId(),
      name: 'Size',
      minSelect: 1,
      maxSelect: 1,
    );
    await a.menu.upsertModifierGroup(size);
    final large = Modifier(
      id: newId(),
      groupId: size.id,
      name: 'Large',
      priceDelta: const Money(200),
    );
    await a.menu.upsertModifier(large);
    final burger = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Burger',
      price: const Money(1000),
      modifierGroupIds: [size.id],
    );
    await a.menu.upsertItem(burger);
    final fries = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Fries',
      price: const Money(350),
    );
    await a.menu.upsertItem(fries);
    final table = DiningTable(id: newId(), label: '5');
    await a.tables.upsertTable(table);

    // Order 1: dine-in, Burger(Large) + 2 Fries, paid cash with a tip.
    final o1 = await a.orders.createOrder(
      type: OrderType.dineIn,
      taxRateBp: 1300,
      tableId: table.id,
    );
    await a.orders.addLine(
      orderId: o1,
      item: burger,
      selectedModifiers: [large],
    );
    await a.orders.addLine(orderId: o1, item: fries, qty: 2);
    // subtotal (1000+200)+700 = 1900; tax 247; total 2147
    final closed = await a.payments.recordApproved(
      orderId: o1,
      method: PaymentMethod.cash,
      amount: const Money(2147),
      tip: const Money(300),
    );
    expect(closed, isTrue);

    // Order 2: takeout with a voided line, still open.
    final o2 = await a.orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await a.orders.addLine(orderId: o2, item: burger);
    final o2Line = (await a.orders.getLines(o2)).single;
    await a.orders.voidLine(o2Line.id);

    // --- Push everything to the cloud ---
    final pushOutcome = await a.sync.syncNow();
    expect(pushOutcome.ok, isTrue);
    expect(pushOutcome.pushed, greaterThan(0));

    // --- A brand-new, empty tablet restores from the cloud ---
    final b = await makeDevice(cloud, clock, 'B');
    addTearDown(b.db.close);
    final restore = await b.sync.restoreFromCloud();
    expect(restore.ok, isTrue);
    expect(restore.pulled, greaterThan(0));

    // Menu reconstructed.
    expect(
      (await b.menu.watchCategories().first).map((c) => c.name),
      contains('Mains'),
    );
    final bItems = await b.menu.watchItemsInCategory(cat.id).first;
    expect(bItems.map((i) => i.name), containsAll(['Burger', 'Fries']));
    final bGroups = await b.menu.getModifierGroupsForItem(burger.id);
    expect(bGroups.single.name, 'Size');
    expect(bGroups.single.modifiers.single.name, 'Large');

    // Tables reconstructed.
    expect((await b.tables.watchTables().first).single.label, '5');

    // Order 1 reconstructed in full.
    final bO1 = (await b.orders.getOrder(o1))!;
    expect(bO1.status, OrderStatus.paid);
    expect(bO1.total, const Money(2147));
    expect(bO1.tableId, table.id);
    final bO1Lines = await b.orders.getLines(o1);
    final bBurgerLine = bO1Lines.firstWhere((l) => l.nameSnapshot == 'Burger');
    expect(bBurgerLine.modifiers.single.nameSnapshot, 'Large');
    final bO1Pays = await b.payments.paymentsForOrder(o1);
    expect(bO1Pays.single.amount, const Money(2147));
    expect(bO1Pays.single.tip, const Money(300));

    // Order 2's voided line survived as a status flip.
    final bO2Lines = await b.orders.getLines(o2);
    expect(bO2Lines.single.status, OrderLineStatus.voided);

    // The day's report matches between the two tablets.
    final ra = await a.reports.dailyReport(DateTime.now());
    final rb = await b.reports.dailyReport(DateTime.now());
    expect(rb.gross, ra.gross);
    expect(rb.collectedTotal, ra.collectedTotal);
    expect(rb.tipsTotal, ra.tipsTotal);
    expect(
      rb.itemSales.map((i) => '${i.name}:${i.qty}').toSet(),
      ra.itemSales.map((i) => '${i.name}:${i.qty}').toSet(),
    );
  });

  test('conflicting edits converge last-write-wins', () async {
    final a = await makeDevice(cloud, clock, 'A');
    final b = await makeDevice(cloud, clock, 'B');
    addTearDown(a.db.close);
    addTearDown(b.db.close);

    final cat = Category(id: newId(), name: 'Mains');
    await a.menu.upsertCategory(cat);
    await a.sync.syncNow();
    await b.sync.syncNow(); // B now has the category

    // A edits first (earlier), B edits the same row second (later).
    await a.menu.upsertCategory(cat.copyWith(name: 'Mains-A'));
    await b.menu.upsertCategory(cat.copyWith(name: 'Mains-B'));

    await a.sync.syncNow(); // push A's older edit
    await b.sync.syncNow(); // B keeps its newer edit, pushes it
    await a.sync.syncNow(); // A pulls B's newer edit

    final aName = (await a.menu.watchCategories().first).single.name;
    final bName = (await b.menu.watchCategories().first).single.name;
    expect(aName, 'Mains-B', reason: 'later write wins on A');
    expect(bName, 'Mains-B', reason: 'later write wins on B');
  });

  test('a hard delete propagates to other devices', () async {
    final a = await makeDevice(cloud, clock, 'A');
    final b = await makeDevice(cloud, clock, 'B');
    addTearDown(a.db.close);
    addTearDown(b.db.close);

    final group = ModifierGroup(id: newId(), name: 'Size');
    await a.menu.upsertModifierGroup(group);
    final mod = Modifier(
      id: newId(),
      groupId: group.id,
      name: 'Large',
      priceDelta: const Money(200),
    );
    await a.menu.upsertModifier(mod);
    await a.sync.syncNow();
    await b.sync.syncNow();
    expect(await b.db.select(b.db.modifiers).get(), hasLength(1));

    await a.menu.deleteModifier(mod.id);
    await a.sync.syncNow();
    await b.sync.syncNow();
    expect(await b.db.select(b.db.modifiers).get(), isEmpty);
  });

  test('sync is a no-op when the cloud is not configured', () async {
    final a = await makeDevice(cloud, clock, 'A', configured: false);
    addTearDown(a.db.close);
    await a.menu.upsertCategory(Category(id: newId(), name: 'Mains'));

    final outcome = await a.sync.syncNow();
    expect(outcome.ok, isFalse);
    // The local change stays unsynced — nothing was pushed or marked.
    expect(await a.sync.journal.unsynced(), isNotEmpty);
  });
}
