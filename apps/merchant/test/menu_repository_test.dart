import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/item_image_repository.dart';
import 'package:merchant/features/menu/data/item_image_store.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

/// Avoids touching the real filesystem (path_provider has no platform in
/// unit tests): returns a fake stored path and records deletions.
class _FakeImageStore extends ItemImageStore {
  final List<String> deleted = [];
  int _n = 0;
  @override
  Future<String> import(String sourcePath) async => '/fake/${_n++}.png';
  @override
  Future<void> delete(String path) async => deleted.add(path);
}

void main() {
  late AppDatabase db;
  late MenuRepository menu;

  setUp(() {
    db = createTestDb();
    menu = MenuRepository(db);
  });

  tearDown(() => db.close());

  test('category and item round-trip with modifier group assignment', () async {
    final cat = Category(id: newId(), name: 'Drinks', sortOrder: 2);
    await menu.upsertCategory(cat);

    final size = ModifierGroup(
      id: newId(),
      name: 'Size',
      minSelect: 1,
      maxSelect: 1,
    );
    await menu.upsertModifierGroup(size);
    await menu.upsertModifier(
      Modifier(id: newId(), groupId: size.id, name: 'Small'),
    );
    await menu.upsertModifier(
      Modifier(
        id: newId(),
        groupId: size.id,
        name: 'Large',
        priceDelta: const Money(100),
      ),
    );

    final cola = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Cola',
      price: const Money(250),
      modifierGroupIds: [size.id],
    );
    await menu.upsertItem(cola);

    final items = await menu.watchItemsInCategory(cat.id).first;
    expect(items.single.name, 'Cola');
    expect(items.single.price, const Money(250));

    final fetched = await menu.getItem(cola.id);
    expect(fetched!.modifierGroupIds, [size.id]);

    final groups = await menu.getModifierGroupsForItem(cola.id);
    expect(groups.single.name, 'Size');
    expect(groups.single.modifiers, hasLength(2));
  });

  test(
    'upsert updates in place; group unassignment removes the join row',
    () async {
      final cat = Category(id: newId(), name: 'Mains');
      await menu.upsertCategory(cat);
      final size = ModifierGroup(id: newId(), name: 'Size');
      await menu.upsertModifierGroup(size);

      final item = MenuItem(
        id: newId(),
        categoryId: cat.id,
        name: 'Pasta',
        price: const Money(1200),
        modifierGroupIds: [size.id],
      );
      await menu.upsertItem(item);
      await menu.upsertItem(
        item.copyWith(price: const Money(1300), modifierGroupIds: []),
      );

      final fetched = await menu.getItem(item.id);
      expect(fetched!.price, const Money(1300));
      expect(fetched.modifierGroupIds, isEmpty);

      final items = await menu.watchItemsInCategory(cat.id).first;
      expect(items, hasLength(1)); // updated, not duplicated
    },
  );

  test(
    'code, second name and custom fields round-trip; fields replace on update',
    () async {
      final cat = Category(id: newId(), name: 'Noodles');
      await menu.upsertCategory(cat);
      final item = MenuItem(
        id: newId(),
        categoryId: cat.id,
        name: 'Beef Noodle',
        price: const Money(1500),
        code: 'A01',
        nameSecondary: '牛肉面',
        attributes: [
          MenuItemAttribute(id: newId(), label: 'Spice', value: 'Medium'),
          MenuItemAttribute(
            id: newId(),
            label: 'Ingredients',
            value: 'Beef, noodles',
          ),
        ],
      );
      await menu.upsertItem(item);

      final fetched = await menu.getItem(item.id);
      expect(fetched!.code, 'A01');
      expect(fetched.nameSecondary, '牛肉面');
      expect(fetched.attributes.map((a) => a.label), ['Spice', 'Ingredients']);
      expect(fetched.attributes.first.value, 'Medium');

      // The list view also carries code + second name (for stacked display).
      final listed = (await menu.watchItemsInCategory(cat.id).first).single;
      expect(listed.code, 'A01');
      expect(listed.nameSecondary, '牛肉面');

      // Saving with fewer fields replaces, never appends.
      await menu.upsertItem(
        fetched.copyWith(attributes: [fetched.attributes.first]),
      );
      final reread = await menu.getItem(item.id);
      expect(reread!.attributes, hasLength(1));
      expect(reread.attributes.single.label, 'Spice');
    },
  );

  test(
    'item images add (ordered), rename, and delete with file cleanup',
    () async {
      final cat = Category(id: newId(), name: 'X');
      await menu.upsertCategory(cat);
      final item = MenuItem(
        id: newId(),
        categoryId: cat.id,
        name: 'A',
        price: const Money(100),
      );
      await menu.upsertItem(item);

      final store = _FakeImageStore();
      final images = ItemImageRepository(db, store: store);
      await images.addImage(itemId: item.id, label: 'front', sourcePath: 'a');
      await images.addImage(itemId: item.id, label: '', sourcePath: 'b');

      var list = await images.watchImages(item.id).first;
      expect(list, hasLength(2));
      expect(list.map((i) => i.sortOrder), [0, 1]);
      final firstId = list.first.id;
      final firstPath = list.first.path;

      await images.renameImage(firstId, 'hero');
      list = await images.watchImages(item.id).first;
      expect(list.firstWhere((i) => i.id == firstId).label, 'hero');

      await images.deleteImage(firstId);
      list = await images.watchImages(item.id).first;
      expect(list, hasLength(1));
      expect(store.deleted, contains(firstPath));
    },
  );

  test('deleting a group cleans up its modifiers and item links', () async {
    final cat = Category(id: newId(), name: 'Mains');
    await menu.upsertCategory(cat);
    final group = ModifierGroup(id: newId(), name: 'Add-ons');
    await menu.upsertModifierGroup(group);
    await menu.upsertModifier(
      Modifier(id: newId(), groupId: group.id, name: 'Cheese'),
    );
    final item = MenuItem(
      id: newId(),
      categoryId: cat.id,
      name: 'Burger',
      price: const Money(1000),
      modifierGroupIds: [group.id],
    );
    await menu.upsertItem(item);

    await menu.deleteModifierGroup(group.id);

    expect(await menu.watchModifierGroups().first, isEmpty);
    expect((await menu.getItem(item.id))!.modifierGroupIds, isEmpty);
  });

  group('deleting items and categories', () {
    test('deleting an item removes it and its links/attributes', () async {
      final cat = Category(id: newId(), name: 'Mains');
      await menu.upsertCategory(cat);
      final group = ModifierGroup(id: newId(), name: 'Add-ons');
      await menu.upsertModifierGroup(group);
      final item = MenuItem(
        id: newId(),
        categoryId: cat.id,
        name: 'Burger',
        price: const Money(1000),
        modifierGroupIds: [group.id],
        attributes: [
          MenuItemAttribute(id: newId(), label: 'Spice', value: 'Hot'),
        ],
      );
      await menu.upsertItem(item);

      await menu.deleteItem(item.id);

      expect(await menu.getItem(item.id), isNull);
      expect(await menu.watchItemsInCategory(cat.id).first, isEmpty);
      // The modifier group itself survives — only the item's link to it went.
      expect(await menu.watchModifierGroups().first, hasLength(1));
    });

    test('deleting a category cascades to all its items', () async {
      final cat = Category(id: newId(), name: 'Drinks');
      await menu.upsertCategory(cat);
      await menu.upsertItem(
        MenuItem(
          id: newId(),
          categoryId: cat.id,
          name: 'Cola',
          price: const Money(250),
        ),
      );
      await menu.upsertItem(
        MenuItem(
          id: newId(),
          categoryId: cat.id,
          name: 'Water',
          price: const Money(150),
        ),
      );

      await menu.deleteCategory(cat.id);

      expect(await menu.watchCategories().first, isEmpty);
      expect(await menu.watchItemsInCategory(cat.id).first, isEmpty);
    });

    test('deleting one category leaves other categories untouched', () async {
      final keep = Category(id: newId(), name: 'Keep', sortOrder: 0);
      final drop = Category(id: newId(), name: 'Drop', sortOrder: 1);
      await menu.upsertCategory(keep);
      await menu.upsertCategory(drop);
      await menu.upsertItem(
        MenuItem(
          id: newId(),
          categoryId: keep.id,
          name: 'Stays',
          price: const Money(100),
        ),
      );

      await menu.deleteCategory(drop.id);

      final cats = await menu.watchCategories().first;
      expect(cats.map((c) => c.name), ['Keep']);
      expect(
        (await menu.watchItemsInCategory(keep.id).first).single.name,
        'Stays',
      );
    });
  });
}
