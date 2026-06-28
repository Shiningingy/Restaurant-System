import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/core/sync/sync_codec.dart';
import 'package:merchant/core/sync/sync_journal.dart';
import 'package:merchant/features/menu/data/item_image_repository.dart';
import 'package:merchant/features/menu/data/item_image_store.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/sync/application/sync_service.dart';
import 'package:merchant/features/sync/data/sync_settings.dart';
import 'package:path/path.dart' as p;
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/sync_harness.dart';
import 'helpers/test_db.dart';

/// In-memory stand-in for the `menu-photos` Storage bucket, shared between the
/// simulated devices so one device's upload is visible to the other.
class _MemObjectStore implements ObjectStore {
  final Map<String, List<int>> objects = {};

  @override
  Future<void> putObject(
    String key,
    List<int> bytes, {
    required String contentType,
  }) async => objects[key] = bytes;

  @override
  Future<List<int>?> getObject(String key) async => objects[key];

  @override
  Future<void> deleteObject(String key) async => objects.remove(key);
}

/// One simulated tablet wired for item-photo sync: a menu repo, an image repo
/// (sharing the journal so a photo change rides the feed), and a sync service
/// whose reconcile downloads/uploads photos.
class _ImgDevice {
  final AppDatabase db;
  final MenuRepository menu;
  final ItemImageRepository imgs;
  final SyncService sync;
  _ImgDevice(this.db, this.menu, this.imgs, this.sync);
}

Future<_ImgDevice> _device(
  TickingClock clock,
  String deviceId,
  FakeCloud cloud,
  ObjectStore store,
  Directory imgDir,
) async {
  final db = createTestDb();
  final journal = SyncJournal(db, clock: clock.now);
  final settings = SyncSettings.inMemory();
  await settings.setConfig(
    const SupabaseConfig(url: 'https://x.supabase.co', anonKey: 'anon'),
  );
  final imgs = ItemImageRepository(
    db,
    store: ItemImageStore(baseDir: imgDir),
    journal: journal,
    objectStore: store,
  );
  final sync = SyncService(
    journal: journal,
    codec: SyncCodec(db),
    settings: settings,
    buildBackend: () => FakeCloudBackend(cloud, deviceId),
    reconcileAssets: () => imgs.reconcile(),
    clock: () => DateTime.utc(2030),
  );
  return _ImgDevice(db, MenuRepository(db, journal: journal), imgs, sync);
}

void main() {
  test('an item photo added on one device syncs, bytes and all, to another '
      'device (refs ride the feed, bytes ride the bucket)', () async {
    final clock = TickingClock();
    final cloud = FakeCloud();
    final bucket = _MemObjectStore();
    final dirA = Directory.systemTemp.createTempSync('imgA');
    final dirB = Directory.systemTemp.createTempSync('imgB');
    addTearDown(() => dirA.deleteSync(recursive: true));
    addTearDown(() => dirB.deleteSync(recursive: true));

    final a = await _device(clock, 'A', cloud, bucket, dirA);
    final b = await _device(clock, 'B', cloud, bucket, dirB);
    addTearDown(a.db.close);
    addTearDown(b.db.close);

    // A: a category, an item, and a photo on the item.
    final cat = Category(id: newId(), name: 'Mains');
    await a.menu.upsertCategory(cat);
    final item = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Tea',
      price: const Money(300),
    );
    await a.menu.upsertItem(item);
    final src = File(p.join(dirA.path, 'src.png'));
    final bytes = Uint8List.fromList(List.generate(64, (i) => i % 256));
    await src.writeAsBytes(bytes);
    await a.imgs.addImage(
      itemId: item.id,
      label: 'Photo',
      sourcePath: src.path,
    );

    // The add put the bytes in the bucket (content-addressed) and re-journalled
    // the item so the ref will sync.
    expect(bucket.objects, hasLength(1));

    // A pushes up; B pulls down and reconciles its photos.
    await a.sync.syncNow();
    await b.sync.syncNow();

    // B now has the item AND the photo, with the bytes downloaded locally.
    final bImgs = await b.imgs.watchImages(item.id).first;
    expect(bImgs, hasLength(1));
    expect(bImgs.single.label, 'Photo');
    expect(bImgs.single.sha, isNotNull);
    expect(bImgs.single.path, isNotEmpty);
    final bBytes = await File(bImgs.single.path).readAsBytes();
    expect(bBytes, bytes, reason: 'the synced file is byte-identical');
    expect(bucket.objects.keys.single, '${bImgs.single.sha}.png');
  });

  test('deleting a photo on one device removes it on the other', () async {
    final clock = TickingClock();
    final cloud = FakeCloud();
    final bucket = _MemObjectStore();
    final dirA = Directory.systemTemp.createTempSync('imgA');
    final dirB = Directory.systemTemp.createTempSync('imgB');
    addTearDown(() => dirA.deleteSync(recursive: true));
    addTearDown(() => dirB.deleteSync(recursive: true));

    final a = await _device(clock, 'A', cloud, bucket, dirA);
    final b = await _device(clock, 'B', cloud, bucket, dirB);
    addTearDown(a.db.close);
    addTearDown(b.db.close);

    final cat = Category(id: newId(), name: 'Mains');
    await a.menu.upsertCategory(cat);
    final item = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Tea',
      price: const Money(300),
    );
    await a.menu.upsertItem(item);
    final src = File(p.join(dirA.path, 'src.png'))
      ..writeAsBytesSync(Uint8List.fromList(List.generate(32, (i) => i)));
    await a.imgs.addImage(
      itemId: item.id,
      label: 'Photo',
      sourcePath: src.path,
    );
    await a.sync.syncNow();
    await b.sync.syncNow();
    expect(await b.imgs.watchImages(item.id).first, hasLength(1));

    // A deletes the photo, then both sync.
    final aImg = (await a.imgs.watchImages(item.id).first).single;
    await a.imgs.deleteImage(aImg.id);
    await a.sync.syncNow();
    await b.sync.syncNow();

    expect(await b.imgs.watchImages(item.id).first, isEmpty);
  });
}
