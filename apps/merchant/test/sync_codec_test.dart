import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/core/sync/sync_codec.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

void main() {
  test(
    'menu_item code, second name and custom fields survive encode → apply on a '
    'second device',
    () async {
      final dbA = createTestDb();
      final menuA = MenuRepository(dbA);
      final catId = newId();
      await menuA.upsertCategory(Category(id: catId, name: 'Noodles'));
      final item = MenuItem(
        id: newId(),
        categoryId: catId,
        name: 'Beef Noodle',
        price: const Money(1500),
        code: 'A01',
        nameSecondary: '牛肉面',
        attributes: [
          MenuItemAttribute(id: newId(), label: 'Spice', value: 'Hot'),
        ],
      );
      await menuA.upsertItem(item);

      final codecA = SyncCodec(dbA);
      final catPayload = await codecA.encode(SyncEntities.category, catId);
      final itemPayload = await codecA.encode(SyncEntities.menuItem, item.id);

      // Apply onto a fresh device — parent category first so the FK resolves.
      final dbB = createTestDb();
      final codecB = SyncCodec(dbB);
      await codecB.applyUpsert(SyncEntities.category, catPayload!);
      await codecB.applyUpsert(SyncEntities.menuItem, itemPayload!);

      final got = await MenuRepository(dbB).getItem(item.id);
      expect(got!.code, 'A01');
      expect(got.nameSecondary, '牛肉面');
      expect(got.attributes.single.label, 'Spice');
      expect(got.attributes.single.value, 'Hot');

      await dbA.close();
      await dbB.close();
    },
  );
}
