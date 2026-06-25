import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/settings/settings_repository.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/online_orders/data/menu_publisher.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_db.dart';

class _FakeObjectStore implements domain.ObjectStore {
  final Map<String, List<int>> objects = {};

  @override
  Future<void> putObject(
    String key,
    List<int> bytes, {
    required String contentType,
  }) async {
    objects[key] = bytes;
  }

  @override
  Future<List<int>?> getObject(String key) async => objects[key];

  @override
  Future<void> deleteObject(String key) async => objects.remove(key);
}

void main() {
  late MenuRepository menu;
  late SettingsRepository settings;
  late domain.MenuItem item;

  setUp(() async {
    final db = createTestDb();
    addTearDown(db.close);
    menu = MenuRepository(db);
    SharedPreferences.setMockInitialValues({});
    settings = SettingsRepository(await SharedPreferences.getInstance());

    final cat = domain.Category(id: domain.newId(), name: 'Mains');
    await menu.upsertCategory(cat);
    item = domain.MenuItem(
      id: domain.newId(),
      categoryId: cat.id,
      name: 'Tea',
      price: const domain.Money(300),
    );
    await menu.upsertItem(item);
  });

  test('publish uploads an item photo and carries its content-addressed ref '
      '(survives JSON round-trip)', () async {
    final store = _FakeObjectStore();
    const bytes = [1, 2, 3, 4];
    final publisher = MenuPublisher(
      menu: menu,
      settings: settings,
      itemPhoto: (id) async =>
          id == item.id ? (bytes: bytes, ext: '.jpg') : null,
      photoStore: store,
    );

    final published = await publisher.build();
    final pub = published.categories.single.items.single;
    final sha = sha256.convert(bytes).toString();
    expect(pub.imageSha, sha);
    expect(pub.imageExt, '.jpg');
    expect(store.objects.keys, contains('$sha.jpg'));

    // The ref survives publish → fetch.
    final roundTripped = domain.PublishedMenu.fromJson(
      jsonDecode(jsonEncode(published.toJson())) as Map<String, dynamic>,
    );
    expect(roundTripped.categories.single.items.single.imageSha, sha);
  });

  test('no photo (or no store) → no ref, no upload', () async {
    final store = _FakeObjectStore();
    // Item has no photo.
    final p1 = await MenuPublisher(
      menu: menu,
      settings: settings,
      itemPhoto: (id) async => null,
      photoStore: store,
    ).build();
    expect(p1.categories.single.items.single.imageSha, isNull);
    expect(store.objects, isEmpty);

    // No store at all.
    final p2 = await MenuPublisher(menu: menu, settings: settings).build();
    expect(p2.categories.single.items.single.imageSha, isNull);
  });
}
