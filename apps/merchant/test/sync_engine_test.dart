import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/sync_harness.dart';

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

void main() {
  late FakeCloud cloud;
  late TickingClock clock;

  setUp(() {
    cloud = FakeCloud();
    clock = TickingClock();
  });

  test('a wiped tablet restores its data from the cloud '
      '(Phase 5 exit criterion)', () async {
    final a = await makeDevice(
      clock,
      'A',
      buildBackend: () => FakeCloudBackend(cloud, 'A'),
    );
    addTearDown(a.db.close);
    final seed = await seedBusiness(a);

    final pushOutcome = await a.sync.syncNow();
    expect(pushOutcome.ok, isTrue);
    expect(pushOutcome.pushed, greaterThan(0));

    // A brand-new, empty tablet restores from the cloud.
    final b = await makeDevice(
      clock,
      'B',
      buildBackend: () => FakeCloudBackend(cloud, 'B'),
    );
    addTearDown(b.db.close);
    final restore = await b.sync.restoreFromCloud();
    expect(restore.ok, isTrue);
    expect(restore.pulled, greaterThan(0));

    await expectDevicesMatch(a, b, seed);
  });

  test('conflicting edits converge last-write-wins', () async {
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
    final a = await makeDevice(
      clock,
      'A',
      buildBackend: () => FakeCloudBackend(cloud, 'A'),
      configured: false,
    );
    addTearDown(a.db.close);
    await a.menu.upsertCategory(Category(id: newId(), name: 'Mains'));

    final outcome = await a.sync.syncNow();
    expect(outcome.ok, isFalse);
    // The local change stays unsynced — nothing was pushed or marked.
    expect(await a.sync.journal.unsynced(), isNotEmpty);
  });
}
