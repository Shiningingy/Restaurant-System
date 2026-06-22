import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/customer_display/application/promo_sync.dart';
import 'package:merchant/features/customer_display/data/promo_image_store.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// In-memory [domain.ObjectStore] standing in for the shop's Supabase Storage
/// bucket — lets us drive a full publish-on-A → pull-on-B round trip offline.
class FakeObjectStore implements domain.ObjectStore {
  final Map<String, List<int>> objects = {};

  @override
  Future<void> putObject(
    String key,
    List<int> bytes, {
    required String contentType,
  }) async {
    objects[key] = List.of(bytes);
  }

  @override
  Future<List<int>?> getObject(String key) async => objects[key];

  @override
  Future<void> deleteObject(String key) async {
    objects.remove(key);
  }
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('promo_sync_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  // A device: its own cache dir + a mutable promo-path list.
  ({PromoImageStore store, List<String> paths, PromoSyncService sync}) device(
    String name,
    FakeObjectStore cloud,
  ) {
    final dir = Directory('${tmp.path}/$name')..createSync();
    final images = PromoImageStore(baseDir: dir);
    final paths = <String>[];
    final sync = PromoSyncService(
      store: cloud,
      images: images,
      readPaths: () => paths,
      writePaths: (p) async {
        paths
          ..clear()
          ..addAll(p);
      },
    );
    return (store: images, paths: paths, sync: sync);
  }

  Future<String> sourceFile(String name, List<int> bytes) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  test('publish on one device, pull carries photos + order to another', () async {
    final cloud = FakeObjectStore();

    // Device A: owner adds two promo photos and publishes.
    final a = device('a', cloud);
    final p1 = await a.store.import(await sourceFile('1.jpg', [1, 2, 3, 4]));
    final p2 = await a.store.import(await sourceFile('2.png', [9, 8, 7]));
    a.paths
      ..add(p1)
      ..add(p2);
    await a.sync.publish();

    // Cloud now holds the manifest + both images.
    expect(cloud.objects.containsKey(domain.PromoManifest.storageKey), isTrue);
    expect(cloud.objects.length, 3);

    // Device B: starts empty, pulls.
    final b = device('b', cloud);
    expect(b.paths, isEmpty);
    final pulled = await b.sync.pull();

    // B now has both photos cached locally, in manifest order, with the same
    // bytes — and the order (1.jpg before 2.png) is preserved.
    expect(pulled, isNotNull);
    expect(b.paths.length, 2);
    expect(await b.store.bytesOf(b.paths[0]), [1, 2, 3, 4]);
    expect(await b.store.bytesOf(b.paths[1]), [9, 8, 7]);
    // Content-addressed: same file names on both devices.
    expect(
      b.paths.map((p) => p.split(Platform.pathSeparator).last),
      [p1, p2].map((p) => p.split(Platform.pathSeparator).last),
    );
  });

  test('pull returns null when nothing was ever published', () async {
    final b = device('b', FakeObjectStore());
    b.paths.add('/local/only.jpg');
    expect(await b.sync.pull(), isNull);
    expect(b.paths, ['/local/only.jpg']); // left untouched
  });

  test('clearing on one device empties the other on next pull', () async {
    final cloud = FakeObjectStore();
    final a = device('a', cloud);
    final p1 = await a.store.import(await sourceFile('1.jpg', [1, 2, 3]));
    a.paths.add(p1);
    await a.sync.publish();

    final b = device('b', cloud);
    await b.sync.pull();
    expect(b.paths, hasLength(1));

    // Owner clears all photos on A and republishes an empty set.
    a.paths.clear();
    await a.sync.publish();

    final applied = await b.sync.pull();
    expect(applied, isEmpty); // explicit empty set, not null
    expect(b.paths, isEmpty);
  });

  test('removing a photo deletes its orphaned object from the bucket', () async {
    final cloud = FakeObjectStore();
    final a = device('a', cloud);
    final keep = await a.store.import(await sourceFile('keep.jpg', [1, 1, 1]));
    final drop = await a.store.import(await sourceFile('drop.jpg', [2, 2, 2]));
    final dropKey = a.store.refOf(drop)!.storageKey;
    a.paths
      ..add(keep)
      ..add(drop);
    await a.sync.publish();
    expect(cloud.objects.containsKey(dropKey), isTrue);

    // Owner removes the second photo and republishes.
    a.paths.remove(drop);
    await a.sync.publish();

    // The dropped photo's bytes are gone; the kept one and manifest remain.
    expect(cloud.objects.containsKey(dropKey), isFalse);
    expect(cloud.objects.containsKey(a.store.refOf(keep)!.storageKey), isTrue);
    expect(cloud.objects.containsKey(domain.PromoManifest.storageKey), isTrue);
  });

  test('re-publishing the same set leaves no duplicates', () async {
    final cloud = FakeObjectStore();
    final a = device('a', cloud);
    a.paths.add(await a.store.import(await sourceFile('p.jpg', [7, 7])));
    await a.sync.publish();
    await a.sync.publish(); // idempotent
    // 1 image + 1 manifest, no extra objects.
    expect(cloud.objects, hasLength(2));
  });

  test('importing identical bytes dedupes to one cache file', () async {
    final a = device('a', FakeObjectStore());
    final src = await sourceFile('x.jpg', [5, 5, 5]);
    final first = await a.store.import(src);
    final again = await a.store.import(await sourceFile('y.jpg', [5, 5, 5]));
    expect(first, again); // same content hash → same path
    expect(await a.store.cachedShas(), hasLength(1));
  });
}
