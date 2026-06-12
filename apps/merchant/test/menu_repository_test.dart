import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

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
}
