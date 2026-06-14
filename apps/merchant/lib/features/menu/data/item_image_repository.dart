import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import 'item_image_store.dart';

/// A renamable image attached to a menu item. Merchant-local (not a shared
/// domain type, not synced this phase).
class ItemImage {
  final String id;
  final String itemId;
  final String label;
  final String path;
  final int sortOrder;

  const ItemImage({
    required this.id,
    required this.itemId,
    required this.label,
    required this.path,
    required this.sortOrder,
  });
}

/// DB rows for item images plus the on-disk file lifecycle. Kept separate from
/// [MenuRepository] because images are binary, device-local, and not journaled.
class ItemImageRepository {
  final AppDatabase db;
  final ItemImageStore store;

  ItemImageRepository(this.db, {ItemImageStore? store})
    : store = store ?? ItemImageStore();

  Stream<List<ItemImage>> watchImages(String itemId) {
    final q = db.select(db.menuItemImages)
      ..where((t) => t.itemId.equals(itemId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.watch().map(
      (rows) => rows
          .map(
            (r) => ItemImage(
              id: r.id,
              itemId: r.itemId,
              label: r.label,
              path: r.path,
              sortOrder: r.sortOrder,
            ),
          )
          .toList(),
    );
  }

  /// Copies [sourcePath] into app storage and records the row.
  Future<void> addImage({
    required String itemId,
    required String label,
    required String sourcePath,
  }) async {
    final stored = await store.import(sourcePath);
    final count = await (db.select(
      db.menuItemImages,
    )..where((t) => t.itemId.equals(itemId))).get().then((r) => r.length);
    await db
        .into(db.menuItemImages)
        .insert(
          MenuItemImagesCompanion.insert(
            id: domain.newId(),
            itemId: itemId,
            label: label,
            path: stored,
            sortOrder: Value(count),
          ),
        );
  }

  Future<void> renameImage(String id, String label) =>
      (db.update(db.menuItemImages)..where((t) => t.id.equals(id))).write(
        MenuItemImagesCompanion(label: Value(label)),
      );

  Future<void> deleteImage(String id) async {
    final row = await (db.select(
      db.menuItemImages,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (db.delete(db.menuItemImages)..where((t) => t.id.equals(id))).go();
    await store.delete(row.path);
  }
}
