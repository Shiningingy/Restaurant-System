import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/payments/data/payment_repository.dart';
import 'package:merchant/features/reports/data/reports_repository.dart';
import 'package:merchant/core/settings/tables_repository.dart';
import 'package:merchant/features/sync/application/sync_service.dart';
import 'package:merchant/core/sync/sync_codec.dart';
import 'package:merchant/core/sync/sync_journal.dart';
import 'package:merchant/features/sync/data/sync_settings.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'test_db.dart';

/// A clock that advances on every read, giving the journal a globally
/// increasing, deterministic change order across simulated devices.
class TickingClock {
  DateTime _t = DateTime.utc(2026, 1, 1);
  DateTime now() {
    _t = _t.add(const Duration(seconds: 1));
    return _t;
  }
}

/// One simulated tablet: its own database, repositories and sync service.
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

/// Builds a device backed by [buildBackend]. The same shared [clock]
/// across devices makes the cross-device change order deterministic.
/// [snapshot] is the optional pre-sync backup hook (default off).
Future<Device> makeDevice(
  TickingClock clock,
  String deviceId, {
  required SyncBackend Function() buildBackend,
  bool configured = true,
  Future<void> Function(String reason)? snapshot,
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
      buildBackend: buildBackend,
      snapshot: snapshot,
      clock: () => DateTime.utc(2030),
    ),
  );
}

/// A shared in-memory stand-in for the restaurant's Supabase change feed.
/// Append-only, upsert-by-id (keyed on the change's own id) — the same
/// contract as the PostgREST `sync_changes` table the real backend talks to.
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

/// Builds a realistic dataset on [d] and returns the ids a restore test
/// asserts against. Shared by the in-memory and over-HTTP engine tests.
class SeededData {
  final String categoryId;
  final String burgerId;
  final String friesId;
  final String tableId;
  final String paidOrderId;
  final String voidedLineOrderId;

  SeededData({
    required this.categoryId,
    required this.burgerId,
    required this.friesId,
    required this.tableId,
    required this.paidOrderId,
    required this.voidedLineOrderId,
  });
}

Future<SeededData> seedBusiness(Device d) async {
  final cat = Category(id: newId(), name: 'Mains');
  await d.menu.upsertCategory(cat);
  final size = ModifierGroup(
    id: newId(),
    name: 'Size',
    minSelect: 1,
    maxSelect: 1,
  );
  await d.menu.upsertModifierGroup(size);
  final large = Modifier(
    id: newId(),
    groupId: size.id,
    name: 'Large',
    priceDelta: const Money(200),
  );
  await d.menu.upsertModifier(large);
  final burger = MenuItem(
    id: newId(),
    categoryId: cat.id,
    name: 'Burger',
    price: const Money(1000),
    modifierGroupIds: [size.id],
  );
  await d.menu.upsertItem(burger);
  final fries = MenuItem(
    id: newId(),
    categoryId: cat.id,
    name: 'Fries',
    price: const Money(350),
  );
  await d.menu.upsertItem(fries);
  final table = DiningTable(id: newId(), label: '5');
  await d.tables.upsertTable(table);

  // Dine-in: Burger(Large) + 2 Fries, paid cash with a tip.
  final o1 = await d.orders.createOrder(
    type: OrderType.dineIn,
    taxRateBp: 1300,
    tableId: table.id,
  );
  await d.orders.addLine(orderId: o1, item: burger, selectedModifiers: [large]);
  await d.orders.addLine(orderId: o1, item: fries, qty: 2);
  await d.payments.recordApproved(
    orderId: o1,
    method: PaymentMethod.cash,
    amount: const Money(2147),
    tip: const Money(300),
  );

  // Takeout with a voided line, still open.
  final o2 = await d.orders.createOrder(
    type: OrderType.takeout,
    taxRateBp: 1300,
  );
  await d.orders.addLine(orderId: o2, item: burger);
  final o2Line = (await d.orders.getLines(o2)).single;
  await d.orders.voidLine(o2Line.id);

  return SeededData(
    categoryId: cat.id,
    burgerId: burger.id,
    friesId: fries.id,
    tableId: table.id,
    paidOrderId: o1,
    voidedLineOrderId: o2,
  );
}

/// Asserts that [restored] reconstructs everything [seed] put on the
/// origin device [origin] — the heart of the restore exit criterion,
/// shared by the in-memory and over-HTTP engine tests.
Future<void> expectDevicesMatch(
  Device origin,
  Device restored,
  SeededData seed,
) async {
  // Menu.
  expect(
    (await restored.menu.watchCategories().first).map((c) => c.name),
    contains('Mains'),
  );
  final items = await restored.menu.watchItemsInCategory(seed.categoryId).first;
  expect(items.map((i) => i.name), containsAll(['Burger', 'Fries']));
  final groups = await restored.menu.getModifierGroupsForItem(seed.burgerId);
  expect(groups.single.name, 'Size');
  expect(groups.single.modifiers.single.name, 'Large');

  // Tables.
  expect((await restored.tables.watchTables().first).single.label, '5');

  // Paid order, in full.
  final order = (await restored.orders.getOrder(seed.paidOrderId))!;
  expect(order.status, OrderStatus.paid);
  expect(order.total, const Money(2147));
  expect(order.tableId, seed.tableId);
  final lines = await restored.orders.getLines(seed.paidOrderId);
  final burgerLine = lines.firstWhere((l) => l.nameSnapshot == 'Burger');
  expect(burgerLine.modifiers.single.nameSnapshot, 'Large');
  final pays = await restored.payments.paymentsForOrder(seed.paidOrderId);
  expect(pays.single.amount, const Money(2147));
  expect(pays.single.tip, const Money(300));

  // Voided line survived as a status flip.
  final voidedLines = await restored.orders.getLines(seed.voidedLineOrderId);
  expect(voidedLines.single.status, OrderLineStatus.voided);

  // The day's report matches between the two tablets.
  final ro = await origin.reports.dailyReport(DateTime.now());
  final rr = await restored.reports.dailyReport(DateTime.now());
  expect(rr.gross, ro.gross);
  expect(rr.collectedTotal, ro.collectedTotal);
  expect(rr.tipsTotal, ro.tipsTotal);
  expect(
    rr.itemSales.map((i) => '${i.name}:${i.qty}').toSet(),
    ro.itemSales.map((i) => '${i.name}:${i.qty}').toSet(),
  );
}
