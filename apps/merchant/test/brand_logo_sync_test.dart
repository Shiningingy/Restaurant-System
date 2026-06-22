import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/settings/brand_logo_store.dart';
import 'package:merchant/core/settings/brand_logo_sync.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// In-memory ObjectStore standing in for the shop's Supabase Storage bucket.
class FakeObjectStore implements domain.ObjectStore {
  final Map<String, List<int>> objects = {};

  @override
  Future<void> putObject(
    String key,
    List<int> bytes, {
    required String contentType,
  }) async => objects[key] = List.of(bytes);

  @override
  Future<List<int>?> getObject(String key) async => objects[key];

  @override
  Future<void> deleteObject(String key) async => objects.remove(key);
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('brand_logo_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  ({BrandLogoStore store, List<String?> path, BrandLogoSyncService sync})
  device(String name, FakeObjectStore cloud) {
    final dir = Directory('${tmp.path}/$name')..createSync();
    final store = BrandLogoStore(slot: 'global', baseDir: dir);
    final path = <String?>[null];
    final sync = BrandLogoSyncService(
      store: cloud,
      logo: store,
      slot: 'global',
      readPath: () => path[0],
      writePath: (p) async => path[0] = p,
    );
    return (store: store, path: path, sync: sync);
  }

  Future<String> source(String name, List<int> bytes) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  test('publish then pull carries the logo to another device', () async {
    final cloud = FakeObjectStore();
    final a = device('a', cloud);
    a.path[0] = await a.store.import(await source('logo.png', [1, 2, 3]));
    await a.sync.publish();

    final b = device('b', cloud);
    expect(await b.sync.pull(), isTrue);
    expect(b.path[0], isNotNull);
    expect(await b.store.bytesOf(b.path[0]!), [1, 2, 3]);
  });

  test('pull is a no-op when nothing was published', () async {
    final b = device('b', FakeObjectStore());
    b.path[0] = '/local/logo.png';
    expect(await b.sync.pull(), isFalse);
    expect(b.path[0], '/local/logo.png');
  });

  test('clearing on one device clears the other on next pull', () async {
    final cloud = FakeObjectStore();
    final a = device('a', cloud);
    a.path[0] = await a.store.import(await source('logo.png', [9]));
    await a.sync.publish();
    final b = device('b', cloud);
    await b.sync.pull();
    expect(b.path[0], isNotNull);

    // Owner clears the logo and republishes.
    await a.store.clear();
    a.path[0] = null;
    await a.sync.publish();

    expect(await b.sync.pull(), isTrue);
    expect(b.path[0], isNull);
  });

  test('replacing the logo deletes the old object from the bucket', () async {
    final cloud = FakeObjectStore();
    final a = device('a', cloud);
    a.path[0] = await a.store.import(await source('old.png', [1]));
    await a.sync.publish();
    final oldKey = 'brand/global/${a.store.refOf(a.path[0]!)!.sha}.png';
    expect(cloud.objects.containsKey(oldKey), isTrue);

    a.path[0] = await a.store.import(await source('new.png', [2]));
    await a.sync.publish();
    expect(cloud.objects.containsKey(oldKey), isFalse);
  });
}
