import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../db/database.dart';

/// Entity names used on the wire. Each is a self-contained aggregate:
/// [menuItem] carries its modifier-group ids, [order] carries its lines
/// and line modifiers. Print jobs are device-local and never sync.
class SyncEntities {
  static const category = 'category';
  static const menuItem = 'menu_item';
  static const modifierGroup = 'modifier_group';
  static const modifier = 'modifier';
  static const diningTable = 'dining_table';
  static const order = 'order';
  static const payment = 'payment';

  /// Restore order matters: parents (categories, groups) before children
  /// (items, modifiers, orders) so foreign keys resolve.
  static const ordered = [
    category,
    modifierGroup,
    modifier,
    menuItem,
    diningTable,
    order,
    payment,
  ];
}

/// Translates Drift rows ⇄ JSON for the sync change feed, and applies a
/// remote change to the local database. The ONLY place the sync wire
/// format is defined — journaling and pull-apply both go through here so
/// they can never drift apart.
class SyncCodec {
  final AppDatabase db;

  SyncCodec(this.db);

  // --- Encode: read the current row(s) and return the wire payload. ---
  // Returns null if the row no longer exists (treat as nothing to journal).

  Future<Map<String, dynamic>?> encode(String entity, String id) async {
    switch (entity) {
      case SyncEntities.category:
        final r = await _row(db.categories, id);
        return r == null
            ? null
            : {
                'id': r.id,
                'name': r.name,
                'sortOrder': r.sortOrder,
                'isActive': r.isActive,
              };
      case SyncEntities.menuItem:
        final r = await _row(db.menuItems, id);
        if (r == null) return null;
        final groups = await (db.select(
          db.menuItemModifierGroups,
        )..where((t) => t.itemId.equals(id))).get();
        final attrs =
            await (db.select(db.menuItemAttributes)
                  ..where((t) => t.itemId.equals(id))
                  ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
                .get();
        return {
          'id': r.id,
          'categoryId': r.categoryId,
          'name': r.name,
          'price': r.price.cents,
          'code': r.code,
          'nameSecondary': r.nameSecondary,
          'sku': r.sku,
          'sortOrder': r.sortOrder,
          'isActive': r.isActive,
          'modifierGroupIds': groups.map((g) => g.groupId).toList(),
          'attributes': [
            for (final a in attrs)
              {'id': a.id, 'label': a.label, 'value': a.value},
          ],
        };
      case SyncEntities.modifierGroup:
        final r = await _row(db.modifierGroups, id);
        return r == null
            ? null
            : {
                'id': r.id,
                'name': r.name,
                'minSelect': r.minSelect,
                'maxSelect': r.maxSelect,
              };
      case SyncEntities.modifier:
        final r = await _row(db.modifiers, id);
        return r == null
            ? null
            : {
                'id': r.id,
                'groupId': r.groupId,
                'name': r.name,
                'priceDelta': r.priceDelta.cents,
              };
      case SyncEntities.diningTable:
        final r = await _row(db.diningTables, id);
        return r == null
            ? null
            : {'id': r.id, 'label': r.label, 'isActive': r.isActive};
      case SyncEntities.order:
        return _encodeOrder(id);
      case SyncEntities.payment:
        final r = await _row(db.payments, id);
        return r == null
            ? null
            : {
                'id': r.id,
                'orderId': r.orderId,
                'method': r.method.name,
                'status': r.status.name,
                'amount': r.amount.cents,
                'tip': r.tip.cents,
                'terminalRef': r.terminalRef,
                'createdAt': r.createdAt.toUtc().toIso8601String(),
              };
    }
    throw ArgumentError('Unknown sync entity: $entity');
  }

  Future<Map<String, dynamic>?> _encodeOrder(String id) async {
    final o = await _row(db.orders, id);
    if (o == null) return null;
    final lines = await (db.select(
      db.orderLines,
    )..where((t) => t.orderId.equals(id))).get();
    final mods = await (db.select(
      db.orderLineModifiers,
    )..where((t) => t.lineId.isIn(lines.map((l) => l.id)))).get();
    return {
      'id': o.id,
      'type': o.type.name,
      'status': o.status.name,
      'tableId': o.tableId,
      'createdAt': o.createdAt.toUtc().toIso8601String(),
      'paidAt': o.paidAt?.toUtc().toIso8601String(),
      'closedAt': o.closedAt?.toUtc().toIso8601String(),
      'taxRateBp': o.taxRateBp,
      'subtotal': o.subtotal.cents,
      'tax': o.tax.cents,
      'total': o.total.cents,
      'note': o.note,
      'lines': [
        for (final l in lines)
          {
            'id': l.id,
            'menuItemId': l.menuItemId,
            'nameSnapshot': l.nameSnapshot,
            'priceSnapshot': l.priceSnapshot.cents,
            'qty': l.qty,
            'lineTotal': l.lineTotal.cents,
            'status': l.status.name,
            'codeSnapshot': l.codeSnapshot,
            'nameSecondarySnapshot': l.nameSecondarySnapshot,
            'note': l.note,
            'modifiers': [
              for (final m in mods.where((m) => m.lineId == l.id))
                {
                  'id': m.id,
                  'nameSnapshot': m.nameSnapshot,
                  'priceDeltaSnapshot': m.priceDeltaSnapshot.cents,
                },
            ],
          },
      ],
    };
  }

  // --- Apply: write a remote change into the local database. ---

  Future<void> applyUpsert(String entity, Map<String, dynamic> p) async {
    switch (entity) {
      case SyncEntities.category:
        await db
            .into(db.categories)
            .insertOnConflictUpdate(
              CategoriesCompanion.insert(
                id: p['id'] as String,
                name: p['name'] as String,
                sortOrder: Value(p['sortOrder'] as int),
                isActive: Value(p['isActive'] as bool),
              ),
            );
        return;
      case SyncEntities.menuItem:
        await db.transaction(() async {
          await db
              .into(db.menuItems)
              .insertOnConflictUpdate(
                MenuItemsCompanion.insert(
                  id: p['id'] as String,
                  categoryId: p['categoryId'] as String,
                  name: p['name'] as String,
                  price: domain.Money(p['price'] as int),
                  code: Value(p['code'] as String?),
                  nameSecondary: Value(p['nameSecondary'] as String?),
                  sku: Value(p['sku'] as String?),
                  sortOrder: Value(p['sortOrder'] as int),
                  isActive: Value(p['isActive'] as bool),
                ),
              );
          await (db.delete(
            db.menuItemModifierGroups,
          )..where((t) => t.itemId.equals(p['id'] as String))).go();
          for (final groupId
              in (p['modifierGroupIds'] as List).cast<String>()) {
            await db
                .into(db.menuItemModifierGroups)
                .insertOnConflictUpdate(
                  MenuItemModifierGroupsCompanion.insert(
                    itemId: p['id'] as String,
                    groupId: groupId,
                  ),
                );
          }
          await (db.delete(
            db.menuItemAttributes,
          )..where((t) => t.itemId.equals(p['id'] as String))).go();
          final attrs = (p['attributes'] as List? ?? const [])
              .cast<Map<String, dynamic>>();
          for (var i = 0; i < attrs.length; i++) {
            final a = attrs[i];
            await db
                .into(db.menuItemAttributes)
                .insertOnConflictUpdate(
                  MenuItemAttributesCompanion.insert(
                    id: a['id'] as String,
                    itemId: p['id'] as String,
                    label: a['label'] as String,
                    value: a['value'] as String,
                    sortOrder: Value(i),
                  ),
                );
          }
        });
        return;
      case SyncEntities.modifierGroup:
        await db
            .into(db.modifierGroups)
            .insertOnConflictUpdate(
              ModifierGroupsCompanion.insert(
                id: p['id'] as String,
                name: p['name'] as String,
                minSelect: Value(p['minSelect'] as int),
                maxSelect: Value(p['maxSelect'] as int),
              ),
            );
        return;
      case SyncEntities.modifier:
        await db
            .into(db.modifiers)
            .insertOnConflictUpdate(
              ModifiersCompanion.insert(
                id: p['id'] as String,
                groupId: p['groupId'] as String,
                name: p['name'] as String,
                priceDelta: domain.Money(p['priceDelta'] as int),
              ),
            );
        return;
      case SyncEntities.diningTable:
        await db
            .into(db.diningTables)
            .insertOnConflictUpdate(
              DiningTablesCompanion.insert(
                id: p['id'] as String,
                label: p['label'] as String,
                isActive: Value(p['isActive'] as bool),
              ),
            );
        return;
      case SyncEntities.order:
        await _applyOrder(p);
        return;
      case SyncEntities.payment:
        await db
            .into(db.payments)
            .insertOnConflictUpdate(
              PaymentsCompanion.insert(
                id: p['id'] as String,
                orderId: p['orderId'] as String,
                method: domain.PaymentMethod.values.byName(
                  p['method'] as String,
                ),
                status: domain.PaymentStatus.values.byName(
                  p['status'] as String,
                ),
                amount: domain.Money(p['amount'] as int),
                tip: domain.Money(p['tip'] as int),
                terminalRef: Value(p['terminalRef'] as String?),
                createdAt: DateTime.parse(p['createdAt'] as String).toLocal(),
              ),
            );
        return;
    }
    throw ArgumentError('Unknown sync entity: $entity');
  }

  Future<void> _applyOrder(Map<String, dynamic> p) async {
    await db.transaction(() async {
      await db
          .into(db.orders)
          .insertOnConflictUpdate(
            OrdersCompanion.insert(
              id: p['id'] as String,
              type: domain.OrderType.values.byName(p['type'] as String),
              status: domain.OrderStatus.values.byName(p['status'] as String),
              tableId: Value(p['tableId'] as String?),
              createdAt: DateTime.parse(p['createdAt'] as String).toLocal(),
              paidAt: Value(
                p['paidAt'] == null
                    ? null
                    : DateTime.parse(p['paidAt'] as String).toLocal(),
              ),
              closedAt: Value(
                p['closedAt'] == null
                    ? null
                    : DateTime.parse(p['closedAt'] as String).toLocal(),
              ),
              taxRateBp: p['taxRateBp'] as int,
              subtotal: domain.Money(p['subtotal'] as int),
              tax: domain.Money(p['tax'] as int),
              total: domain.Money(p['total'] as int),
              note: Value(p['note'] as String?),
            ),
          );
      // Lines are rewritten wholesale: the order payload is authoritative.
      final lineRows = await (db.select(
        db.orderLines,
      )..where((t) => t.orderId.equals(p['id'] as String))).get();
      await (db.delete(
        db.orderLineModifiers,
      )..where((t) => t.lineId.isIn(lineRows.map((l) => l.id)))).go();
      await (db.delete(
        db.orderLines,
      )..where((t) => t.orderId.equals(p['id'] as String))).go();
      for (final l in (p['lines'] as List).cast<Map<String, dynamic>>()) {
        await db
            .into(db.orderLines)
            .insert(
              OrderLinesCompanion.insert(
                id: l['id'] as String,
                orderId: p['id'] as String,
                menuItemId: l['menuItemId'] as String,
                nameSnapshot: l['nameSnapshot'] as String,
                priceSnapshot: domain.Money(l['priceSnapshot'] as int),
                qty: l['qty'] as int,
                lineTotal: domain.Money(l['lineTotal'] as int),
                status: domain.OrderLineStatus.values.byName(
                  l['status'] as String,
                ),
                codeSnapshot: Value(l['codeSnapshot'] as String?),
                nameSecondarySnapshot: Value(
                  l['nameSecondarySnapshot'] as String?,
                ),
                note: Value(l['note'] as String?),
              ),
            );
        for (final m in (l['modifiers'] as List).cast<Map<String, dynamic>>()) {
          await db
              .into(db.orderLineModifiers)
              .insert(
                OrderLineModifiersCompanion.insert(
                  id: m['id'] as String,
                  lineId: l['id'] as String,
                  nameSnapshot: m['nameSnapshot'] as String,
                  priceDeltaSnapshot: domain.Money(
                    m['priceDeltaSnapshot'] as int,
                  ),
                ),
              );
        }
      }
    });
  }

  Future<void> applyDelete(String entity, String id) async {
    switch (entity) {
      case SyncEntities.modifier:
        await (db.delete(db.modifiers)..where((t) => t.id.equals(id))).go();
        return;
      case SyncEntities.modifierGroup:
        await (db.delete(
          db.menuItemModifierGroups,
        )..where((t) => t.groupId.equals(id))).go();
        await (db.delete(
          db.modifiers,
        )..where((t) => t.groupId.equals(id))).go();
        await (db.delete(
          db.modifierGroups,
        )..where((t) => t.id.equals(id))).go();
        return;
      case SyncEntities.order:
        // An owner deleted the order from history — cascade like the local
        // delete so the row and its children disappear here too.
        final lineRows = await (db.select(
          db.orderLines,
        )..where((t) => t.orderId.equals(id))).get();
        await (db.delete(
          db.orderLineModifiers,
        )..where((t) => t.lineId.isIn(lineRows.map((l) => l.id)))).go();
        await (db.delete(
          db.orderLines,
        )..where((t) => t.orderId.equals(id))).go();
        await (db.delete(db.payments)..where((t) => t.orderId.equals(id))).go();
        await (db.delete(db.orders)..where((t) => t.id.equals(id))).go();
        return;
    }
    // Remaining entities are never hard-deleted (voids are status flips).
  }

  Future<T?> _row<T, Tbl extends Table>(
    TableInfo<Tbl, T> table,
    String id,
  ) async {
    return (db.select(
      table,
    )..where((t) => (t as dynamic).id.equals(id))).getSingleOrNull();
  }
}
