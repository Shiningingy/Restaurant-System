import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import '../../../core/sync/sync_codec.dart';
import '../../../core/sync/sync_journal.dart';

class MenuRepository {
  final AppDatabase db;
  final SyncJournal journal;

  MenuRepository(this.db, {SyncJournal? journal})
    : journal = journal ?? SyncJournal(db);

  // --- Categories ---

  Stream<List<domain.Category>> watchCategories() {
    final q = db.select(db.categories)
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return q.watch().map((rows) => rows.map(_categoryFromRow).toList());
  }

  Future<void> upsertCategory(domain.Category category) {
    return db.transaction(() async {
      await db
          .into(db.categories)
          .insertOnConflictUpdate(
            CategoriesCompanion.insert(
              id: category.id,
              name: category.name,
              sortOrder: Value(category.sortOrder),
              isActive: Value(category.isActive),
            ),
          );
      await journal.recordUpsert(SyncEntities.category, category.id);
    });
  }

  /// Deletes a category and all of its items (cascade). Hard delete is safe:
  /// order lines snapshot the item name/price, so order history is untouched.
  Future<void> deleteCategory(String id) {
    return db.transaction(() async {
      final itemIds =
          await (db.select(db.menuItems)
                ..where((t) => t.categoryId.equals(id)))
              .get()
              .then((rows) => rows.map((r) => r.id).toList());
      for (final itemId in itemIds) {
        await _deleteItemTx(itemId);
      }
      await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
      await journal.recordDelete(SyncEntities.category, id);
    });
  }

  // --- Menu items ---

  Stream<List<domain.MenuItem>> watchItemsInCategory(String categoryId) {
    final q = db.select(db.menuItems)
      ..where((t) => t.categoryId.equals(categoryId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return q.watch().map((rows) => rows.map(_itemFromRow).toList());
  }

  /// Item with its modifier-group ids and custom attributes filled in — for
  /// the item editor.
  Future<domain.MenuItem?> getItem(String itemId) async {
    final row = await (db.select(
      db.menuItems,
    )..where((t) => t.id.equals(itemId))).getSingleOrNull();
    if (row == null) return null;
    final groupIds = await _groupIdsForItem(itemId);
    final attributes = await _attributesForItem(itemId);
    return _itemFromRow(
      row,
    ).copyWith(modifierGroupIds: groupIds, attributes: attributes);
  }

  Future<void> upsertItem(domain.MenuItem item) {
    return db.transaction(() async {
      await db
          .into(db.menuItems)
          .insertOnConflictUpdate(
            MenuItemsCompanion.insert(
              id: item.id,
              categoryId: item.categoryId,
              name: item.name,
              price: item.price,
              code: Value(item.code),
              nameSecondary: Value(item.nameSecondary),
              sku: Value(item.sku),
              sortOrder: Value(item.sortOrder),
              isActive: Value(item.isActive),
            ),
          );
      await (db.delete(
        db.menuItemModifierGroups,
      )..where((t) => t.itemId.equals(item.id))).go();
      for (final groupId in item.modifierGroupIds) {
        await db
            .into(db.menuItemModifierGroups)
            .insert(
              MenuItemModifierGroupsCompanion.insert(
                itemId: item.id,
                groupId: groupId,
              ),
            );
      }
      await (db.delete(
        db.menuItemAttributes,
      )..where((t) => t.itemId.equals(item.id))).go();
      for (var i = 0; i < item.attributes.length; i++) {
        final a = item.attributes[i];
        await db
            .into(db.menuItemAttributes)
            .insert(
              MenuItemAttributesCompanion.insert(
                id: a.id,
                itemId: item.id,
                label: a.label,
                value: a.value,
                sortOrder: Value(i),
              ),
            );
      }
      await journal.recordUpsert(SyncEntities.menuItem, item.id);
    });
  }

  /// Deletes a single item (and its modifier-group links, attributes and
  /// image rows). Hard delete is safe: order lines snapshot the item, so
  /// order history is untouched. Image files on disk are device-local and
  /// not synced; their rows go here, the bytes are swept by the image store.
  Future<void> deleteItem(String id) =>
      db.transaction(() => _deleteItemTx(id));

  /// The body of [deleteItem] without its own transaction, so [deleteCategory]
  /// can cascade many items inside one transaction.
  Future<void> _deleteItemTx(String id) async {
    await (db.delete(
      db.menuItemModifierGroups,
    )..where((t) => t.itemId.equals(id))).go();
    await (db.delete(
      db.menuItemAttributes,
    )..where((t) => t.itemId.equals(id))).go();
    await (db.delete(
      db.menuItemImages,
    )..where((t) => t.itemId.equals(id))).go();
    await (db.delete(db.menuItems)..where((t) => t.id.equals(id))).go();
    await journal.recordDelete(SyncEntities.menuItem, id);
  }

  Future<List<domain.MenuItemAttribute>> _attributesForItem(
    String itemId,
  ) async {
    final rows =
        await (db.select(db.menuItemAttributes)
              ..where((t) => t.itemId.equals(itemId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows
        .map(
          (r) => domain.MenuItemAttribute(
            id: r.id,
            label: r.label,
            value: r.value,
            sortOrder: r.sortOrder,
          ),
        )
        .toList();
  }

  /// The modifier groups (with their modifiers) offered for an item —
  /// what the order screen needs when the item is tapped.
  Future<List<domain.ModifierGroup>> getModifierGroupsForItem(
    String itemId,
  ) async {
    final groupIds = await _groupIdsForItem(itemId);
    if (groupIds.isEmpty) return [];
    final groups = await (db.select(
      db.modifierGroups,
    )..where((t) => t.id.isIn(groupIds))).get();
    final mods = await (db.select(
      db.modifiers,
    )..where((t) => t.groupId.isIn(groupIds))).get();
    return [
      for (final g in groups)
        _groupFromRow(g).copyWith(
          modifiers: mods
              .where((m) => m.groupId == g.id)
              .map(_modifierFromRow)
              .toList(),
        ),
    ];
  }

  Future<List<String>> _groupIdsForItem(String itemId) async {
    final rows = await (db.select(
      db.menuItemModifierGroups,
    )..where((t) => t.itemId.equals(itemId))).get();
    return rows.map((r) => r.groupId).toList();
  }

  // --- Modifier groups & modifiers ---

  Stream<List<domain.ModifierGroup>> watchModifierGroups() {
    final join = db.select(db.modifierGroups).join([
      leftOuterJoin(
        db.modifiers,
        db.modifiers.groupId.equalsExp(db.modifierGroups.id),
      ),
    ]);
    return join.watch().map((rows) {
      final groups = <String, domain.ModifierGroup>{};
      for (final row in rows) {
        final g = row.readTable(db.modifierGroups);
        groups.putIfAbsent(g.id, () => _groupFromRow(g));
        final m = row.readTableOrNull(db.modifiers);
        if (m != null) {
          final current = groups[g.id]!;
          groups[g.id] = current.copyWith(
            modifiers: [...current.modifiers, _modifierFromRow(m)],
          );
        }
      }
      final list = groups.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<void> upsertModifierGroup(domain.ModifierGroup group) {
    return db.transaction(() async {
      await db
          .into(db.modifierGroups)
          .insertOnConflictUpdate(
            ModifierGroupsCompanion.insert(
              id: group.id,
              name: group.name,
              minSelect: Value(group.minSelect),
              maxSelect: Value(group.maxSelect),
            ),
          );
      await journal.recordUpsert(SyncEntities.modifierGroup, group.id);
    });
  }

  Future<void> upsertModifier(domain.Modifier modifier) {
    return db.transaction(() async {
      await db
          .into(db.modifiers)
          .insertOnConflictUpdate(
            ModifiersCompanion.insert(
              id: modifier.id,
              groupId: modifier.groupId,
              name: modifier.name,
              priceDelta: modifier.priceDelta,
            ),
          );
      await journal.recordUpsert(SyncEntities.modifier, modifier.id);
    });
  }

  /// Hard deletes are safe here: order lines snapshot modifier names and
  /// prices, so history never references these rows.
  Future<void> deleteModifier(String id) {
    return db.transaction(() async {
      await (db.delete(db.modifiers)..where((t) => t.id.equals(id))).go();
      await journal.recordDelete(SyncEntities.modifier, id);
    });
  }

  Future<void> deleteModifierGroup(String id) {
    return db.transaction(() async {
      final modifierIds =
          await (db.select(db.modifiers)..where((t) => t.groupId.equals(id)))
              .get()
              .then((rows) => rows.map((r) => r.id).toList());
      await (db.delete(
        db.menuItemModifierGroups,
      )..where((t) => t.groupId.equals(id))).go();
      await (db.delete(db.modifiers)..where((t) => t.groupId.equals(id))).go();
      await (db.delete(db.modifierGroups)..where((t) => t.id.equals(id))).go();
      for (final modifierId in modifierIds) {
        await journal.recordDelete(SyncEntities.modifier, modifierId);
      }
      await journal.recordDelete(SyncEntities.modifierGroup, id);
    });
  }

  // --- Row -> entity mapping ---

  domain.Category _categoryFromRow(CategoryRow r) => domain.Category(
    id: r.id,
    name: r.name,
    sortOrder: r.sortOrder,
    isActive: r.isActive,
  );

  domain.MenuItem _itemFromRow(MenuItemRow r) => domain.MenuItem(
    id: r.id,
    categoryId: r.categoryId,
    name: r.name,
    price: r.price,
    code: r.code,
    nameSecondary: r.nameSecondary,
    sku: r.sku,
    sortOrder: r.sortOrder,
    isActive: r.isActive,
  );

  domain.ModifierGroup _groupFromRow(ModifierGroupRow r) =>
      domain.ModifierGroup(
        id: r.id,
        name: r.name,
        minSelect: r.minSelect,
        maxSelect: r.maxSelect,
      );

  domain.Modifier _modifierFromRow(ModifierRow r) => domain.Modifier(
    id: r.id,
    groupId: r.groupId,
    name: r.name,
    priceDelta: r.priceDelta,
  );
}
