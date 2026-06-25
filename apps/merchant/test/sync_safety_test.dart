import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/sync/data/sync_settings.dart';
import 'package:merchant/features/sync/drivers/noop_sync_backend.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/sync_harness.dart';

void main() {
  test('pendingPush counts unsynced changes and deletions', () async {
    final clock = TickingClock();
    final d = await makeDevice(
      clock,
      'A',
      buildBackend: () => const NoopSyncBackend(),
    );

    // Nothing journalled yet → nothing to push.
    expect((await d.sync.pendingPush()).isEmpty, isTrue);

    // An upsert is a non-delete change.
    await d.menu.upsertCategory(Category(id: newId(), name: 'Mains'));
    var p = await d.sync.pendingPush();
    expect(p.total, 1);
    expect(p.deletes, 0);

    // Deleting it journals a delete on top.
    final cat = (await d.menu.watchCategories().first).single;
    await d.menu.deleteCategory(cat.id);
    p = await d.sync.pendingPush();
    expect(p.isEmpty, isFalse);
    expect(p.deletes, greaterThanOrEqualTo(1));
  });

  test('changing the backend URL clears the sync bookkeeping', () async {
    final s = SyncSettings.inMemory();
    await s.setConfig(
      const SupabaseConfig(url: 'https://a.supabase.co', anonKey: 'k'),
    );
    await s.setCursor(DateTime.utc(2026, 6, 1));
    await s.setLastSyncedAt(DateTime.utc(2026, 6, 1));
    expect(s.lastSyncedAt, isNotNull);

    // Same URL (just a new key) keeps the bookkeeping.
    await s.setConfig(
      const SupabaseConfig(url: 'https://a.supabase.co', anonKey: 'k2'),
    );
    expect(s.lastSyncedAt, isNotNull);

    // A different backend clears it, so the next sync is treated as a first
    // sync (cursor back to epoch, lastSyncedAt null → the UI warns).
    await s.setConfig(
      const SupabaseConfig(url: 'https://b.supabase.co', anonKey: 'k'),
    );
    expect(s.lastSyncedAt, isNull);
    expect(s.cursor, SyncSettings.epoch);
  });
}
