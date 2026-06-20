import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/menu/data/sample_menu.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

/// Exercises the menu stack against a real bilingual restaurant menu
/// (Yee Sushi): item codes, stacked second-name lines and integer-cents
/// prices all round-trip through the repository.
void main() {
  late AppDatabase db;
  late MenuRepository menu;

  setUp(() {
    db = createTestDb();
    menu = MenuRepository(db);
  });

  tearDown(() => db.close());

  test('the fixture itself is well-formed', () {
    final data = yeeSushiMenu();
    expect(data.categories, hasLength(7));
    expect(data.items, hasLength(29));

    // Every item has a positive price and belongs to a known category.
    final categoryIds = {for (final c in data.categories) c.id};
    for (final item in data.items) {
      expect(item.price.cents, greaterThan(0), reason: item.name);
      expect(categoryIds, contains(item.categoryId), reason: item.name);
    }

    // Codes (where present) are unique — they're how staff order "by number".
    final codes = [
      for (final i in data.items)
        if (i.code != null) i.code!,
    ];
    expect(codes.toSet(), hasLength(codes.length));
    // The two sides carry no code.
    expect(data.items.where((i) => i.code == null), hasLength(2));
  });

  test(
    'seeds into the repository and groups under categories in order',
    () async {
      await seedYeeSushiMenu(menu);

      final categories = await menu.watchCategories().first;
      expect(categories.map((c) => c.name), [
        'Yee poke bowls',
        'Yee platters',
        'Yee rolls',
        'Yee special rolls',
        'Yee combos',
        'Torch combo',
        'Sides',
      ]);

      // Rolls come back in code order A01..A08.
      final rolls = await menu.watchItemsInCategory('cat-roll').first;
      expect(rolls.map((i) => i.code), [
        'A01',
        'A02',
        'A03',
        'A04',
        'A05',
        'A06',
        'A07',
        'A08',
      ]);
    },
  );

  test('an item round-trips its code, both name lines and price', () async {
    await seedYeeSushiMenu(menu);

    final unagi = await menu.getItem('item-P01');
    expect(unagi, isNotNull);
    expect(unagi!.code, 'P01');
    expect(unagi.name, 'Unagi poke');
    expect(unagi.nameSecondary, '鳗鱼波奇饭');
    expect(unagi.price, const Money(1399));
    expect(unagi.price.format(), r'$13.99');

    final vegRoll = await menu.getItem('item-A01');
    expect(vegRoll!.nameSecondary, '蔬菜卷');
    expect(vegRoll.price.format(), r'$8.49');

    // A platter has a price but no second-name line.
    final platter = await menu.getItem('item-T03');
    expect(platter!.price, const Money(6000));
    expect(platter.nameSecondary, isNull);
  });

  test(
    'a coded item can be looked up the way staff order — by number',
    () async {
      await seedYeeSushiMenu(menu);

      final all = <MenuItem>[
        for (final c in await menu.watchCategories().first)
          ...await menu.watchItemsInCategory(c.id).first,
      ];
      MenuItem byCode(String code) => all.firstWhere((i) => i.code == code);

      expect(byCode('C06').name, 'Supreme Salmon combo (14pc)');
      expect(byCode('C06').price.format(), r'$19.99');
      expect(byCode('B02').nameSecondary, '飞鱼籽三文鱼卷');
    },
  );
}
