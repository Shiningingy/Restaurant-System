import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import 'menu_repository.dart';

/// The Yee Sushi menu (8200 Birchmount Rd Unit L, Unionville, ON) transcribed
/// from the restaurant's bilingual menu — a realistic English + 中文 sample
/// exercising item codes, second-name lines and integer-cents prices.
///
/// Used both as a test fixture and as optional in-app sample data (Menu tab →
/// "Load sample menu"). Ids are deterministic, so [seedYeeSushiMenu] is
/// idempotent — loading twice upserts the same rows rather than duplicating.
///
/// Chinese second names are transcribed from the menu photo; correct them
/// here if any differ from the printed menu. Prices are integer cents
/// ($8.49 → `Money(849)`), per docs/PRINCIPLES.md.
class YeeSushiMenu {
  final List<domain.Category> categories;
  final List<domain.MenuItem> items;
  const YeeSushiMenu({required this.categories, required this.items});

  /// Items belonging to [category], in menu order.
  List<domain.MenuItem> itemsIn(domain.Category category) =>
      items.where((i) => i.categoryId == category.id).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

/// Builds the full menu with deterministic ids (stable across runs so tests
/// can reference specific rows and re-seeding is idempotent).
YeeSushiMenu yeeSushiMenu() {
  const pokeBowls = domain.Category(id: 'cat-poke', name: 'Yee poke bowls');
  const platters = domain.Category(
    id: 'cat-platter',
    name: 'Yee platters',
    sortOrder: 1,
  );
  const rolls = domain.Category(
    id: 'cat-roll',
    name: 'Yee rolls',
    sortOrder: 2,
  );
  const specialRolls = domain.Category(
    id: 'cat-special',
    name: 'Yee special rolls',
    sortOrder: 3,
  );
  const combos = domain.Category(
    id: 'cat-combo',
    name: 'Yee combos',
    sortOrder: 4,
  );
  const torch = domain.Category(
    id: 'cat-torch',
    name: 'Torch combo',
    sortOrder: 5,
  );
  const sides = domain.Category(id: 'cat-sides', name: 'Sides', sortOrder: 6);

  domain.MenuItem item(
    domain.Category category,
    int order, {
    String? code,
    required String name,
    String? second,
    required int cents,
  }) => domain.MenuItem(
    id: 'item-${code ?? name.toLowerCase().replaceAll(' ', '-')}',
    categoryId: category.id,
    code: code,
    name: name,
    nameSecondary: second,
    price: domain.Money(cents),
    sortOrder: order,
  );

  final items = <domain.MenuItem>[
    // --- Yee poke bowls (忆之波奇饭) — all $13.99 ---
    item(
      pokeBowls,
      0,
      code: 'P01',
      name: 'Unagi poke',
      second: '鳗鱼波奇饭',
      cents: 1399,
    ),
    item(
      pokeBowls,
      1,
      code: 'P02',
      name: 'Tempura shrimp poke',
      second: '天妇罗虾波奇饭',
      cents: 1399,
    ),
    item(
      pokeBowls,
      2,
      code: 'P03',
      name: 'Salmon poke',
      second: '三文鱼波奇饭',
      cents: 1399,
    ),
    item(
      pokeBowls,
      3,
      code: 'P04',
      name: 'Tuna poke',
      second: '金枪鱼波奇饭',
      cents: 1399,
    ),

    // --- Yee platters (忆之大拼盘) ---
    item(platters, 0, code: 'T01', name: 'Yee platter #1 (52pc)', cents: 4000),
    item(platters, 1, code: 'T02', name: 'Yee platter #2 (43pc)', cents: 5000),
    item(platters, 2, code: 'T03', name: 'Yee platter #3 (48pc)', cents: 6000),

    // --- Yee rolls (忆之寿司卷) ---
    item(
      rolls,
      0,
      code: 'A01',
      name: 'Vegetable roll (8pc)',
      second: '蔬菜卷',
      cents: 849,
    ),
    item(
      rolls,
      1,
      code: 'A02',
      name: 'California roll (8pc)',
      second: '加州卷',
      cents: 899,
    ),
    item(
      rolls,
      2,
      code: 'A03',
      name: 'Spicy California roll (8pc)',
      second: '香辣加州卷',
      cents: 949,
    ),
    item(
      rolls,
      3,
      code: 'A04',
      name: 'Crunchy cali roll (8pc)',
      second: '香辣脆加州卷',
      cents: 999,
    ),
    item(
      rolls,
      4,
      code: 'A05',
      name: 'Salmon avocado roll (8pc)',
      second: '三文鱼牛油果卷',
      cents: 1099,
    ),
    item(
      rolls,
      5,
      code: 'A06',
      name: 'Spicy Salmon roll (8pc)',
      second: '香辣三文鱼卷',
      cents: 1099,
    ),
    item(
      rolls,
      6,
      code: 'A07',
      name: 'Spicy Tempura shrimp roll (8pc)',
      second: '香辣天妇罗虾卷',
      cents: 1099,
    ),
    item(
      rolls,
      7,
      code: 'A08',
      name: 'Mini vegetable roll (16pc)',
      second: '迷你蔬菜卷',
      cents: 849,
    ),

    // --- Yee special rolls (忆之特色卷) — all $12.99 ---
    item(
      specialRolls,
      0,
      code: 'B01',
      name: 'Avocado roll (8pc)',
      second: '牛油果卷',
      cents: 1299,
    ),
    item(
      specialRolls,
      1,
      code: 'B02',
      name: 'Tobiko salmon roll (8pc)',
      second: '飞鱼籽三文鱼卷',
      cents: 1299,
    ),
    item(
      specialRolls,
      2,
      code: 'B03',
      name: 'Maple salmon roll (8pc)',
      second: '枫糖三文鱼卷',
      cents: 1299,
    ),

    // --- Yee combos (忆之特色套餐) ---
    item(
      combos,
      0,
      code: 'C01',
      name: 'Veggie combo (16pc)',
      second: '素食套餐',
      cents: 1599,
    ),
    item(
      combos,
      1,
      code: 'C02',
      name: 'Signature combo (13pc)',
      second: '招牌套餐',
      cents: 1699,
    ),
    item(
      combos,
      2,
      code: 'C03',
      name: 'Rainbow combo (13pc)',
      second: '彩虹套餐',
      cents: 1699,
    ),
    item(
      combos,
      3,
      code: 'C04',
      name: 'Salmon combo (10pc)',
      second: '三文鱼套餐',
      cents: 1699,
    ),
    item(
      combos,
      4,
      code: 'C05',
      name: 'Nigiri combo (6pc)',
      second: '握寿司套餐',
      cents: 1199,
    ),
    item(
      combos,
      5,
      code: 'C06',
      name: 'Supreme Salmon combo (14pc)',
      second: '至尊三文鱼套餐',
      cents: 1999,
    ),

    // --- Torch combo (烧烤套餐) ---
    item(
      torch,
      0,
      code: 'Z01',
      name: 'Torch lunch combo (8pc)',
      second: '烧烤午餐套餐',
      cents: 1299,
    ),
    item(
      torch,
      1,
      code: 'Z02',
      name: 'Torch seafood combo',
      second: '烧烤海鲜套餐',
      cents: 1999,
    ),
    item(
      torch,
      2,
      code: 'Z03',
      name: 'Torch Salmon combo (14pc)',
      second: '烧烤三文鱼套餐',
      cents: 2099,
    ),

    // --- Sides (no item code on the menu) ---
    item(sides, 0, name: 'Seaweed salad', second: '海藻沙拉', cents: 399),
    item(sides, 1, name: 'Miso soup', second: '味噌汤', cents: 299),
  ];

  return YeeSushiMenu(
    categories: [
      pokeBowls,
      platters,
      rolls,
      specialRolls,
      combos,
      torch,
      sides,
    ],
    items: items,
  );
}

/// Seeds the whole Yee Sushi menu into [menu] — categories first (items
/// reference them by id), then items. Idempotent (deterministic ids).
Future<void> seedYeeSushiMenu(MenuRepository menu) async {
  final data = yeeSushiMenu();
  for (final category in data.categories) {
    await menu.upsertCategory(category);
  }
  for (final item in data.items) {
    await menu.upsertItem(item);
  }
}
