import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/menu/data/merchant_menu_host.dart';
import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:restaurant_extension_api/restaurant_extension_api.dart';

import 'helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late MenuRepository menu;
  late MerchantMenuHost host;

  setUp(() {
    db = createTestDb();
    menu = MenuRepository(db);
    host = MerchantMenuHost(
      db: db,
      menu: menu,
      canPublish: false,
      publish: () async => const [],
    );
  });

  tearDown(() => db.close());

  const rolls = Category(id: 'cat-roll', name: 'Rolls');

  MenuItem roll(String id, {List<MenuItemAttribute> attributes = const []}) =>
      MenuItem(
        id: id,
        categoryId: rolls.id,
        name: 'Roll $id',
        price: const Money(899),
        attributes: attributes,
      );

  test('loadMenu returns items whole, attributes included', () async {
    await menu.upsertCategory(rolls);
    await menu.upsertItem(
      roll(
        'a',
        attributes: const [
          MenuItemAttribute(id: 'x', label: 'Allergens', value: 'sesame'),
        ],
      ),
    );

    final snapshot = await host.loadMenu();

    expect(snapshot.categories.map((c) => c.id), ['cat-roll']);
    expect(snapshot.items.single.attributes.single.value, 'sesame');
  });

  test('apply writes categories, items and deletes together', () async {
    await menu.upsertCategory(rolls);
    await menu.upsertItem(roll('old'));

    const sides = Category(id: 'cat-sides', name: 'Sides', sortOrder: 1);
    await host.apply(
      MenuChangeSet(
        upsertCategories: const [sides],
        upsertItems: [
          roll('new'),
          const MenuItem(
            id: 'miso',
            categoryId: 'cat-sides',
            name: 'Miso soup',
            price: Money(299),
          ),
        ],
        deleteItemIds: const ['old'],
      ),
    );

    final snapshot = await host.loadMenu();
    expect(snapshot.categories.map((c) => c.id), ['cat-roll', 'cat-sides']);
    expect(snapshot.items.map((i) => i.id).toSet(), {'new', 'miso'});
  });

  test('an item in a missing category is rejected and nothing is written', () {
    final changes = MenuChangeSet(
      upsertCategories: const [rolls],
      upsertItems: [
        roll('ok'),
        const MenuItem(
          id: 'lost',
          categoryId: 'cat-nowhere',
          name: 'Lost item',
          price: Money(100),
        ),
      ],
    );

    expect(host.apply(changes), throwsA(isA<MenuChangeRejected>()));
  });

  test('a failure part-way through rolls the whole batch back', () async {
    // Two attributes sharing an id make the database refuse the second item,
    // after the category and the first item were already written.
    final changes = MenuChangeSet(
      upsertCategories: const [rolls],
      upsertItems: [
        roll('first'),
        roll(
          'second',
          attributes: const [
            MenuItemAttribute(id: 'dup', label: 'A', value: '1'),
            MenuItemAttribute(id: 'dup', label: 'B', value: '2'),
          ],
        ),
      ],
    );

    await expectLater(host.apply(changes), throwsA(anything));

    final snapshot = await host.loadMenu();
    expect(snapshot.categories, isEmpty);
    expect(await menu.getItem('first'), isNull);
  });
}
