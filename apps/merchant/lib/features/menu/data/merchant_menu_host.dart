import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_extension_api/restaurant_extension_api.dart';

import '../../../core/db/database.dart';
import 'menu_repository.dart';

/// The merchant app's [MenuHost]: how extensions read and change the menu.
///
/// Writes go through [MenuRepository], so they are journaled for sync exactly
/// like edits made by hand. [apply] wraps the whole batch in one outer
/// transaction; Drift nests the repository's own transactions inside it, so
/// the batch — sync journal rows included — commits or rolls back together.
class MerchantMenuHost implements MenuHost {
  MerchantMenuHost({
    required this.db,
    required this.menu,
    required this.canPublish,
    required this._publish,
  });

  final AppDatabase db;
  final MenuRepository menu;
  @override
  final bool canPublish;
  final Future<List<String>> Function() _publish;

  @override
  Future<MenuSnapshot> loadMenu() async {
    final categories = await menu.watchCategories().first;
    final items = <domain.MenuItem>[];
    for (final category in categories) {
      // The category stream skips attributes and modifier links; load each
      // item whole so an extension's edit can't wipe them.
      for (final row in await menu.watchItemsInCategory(category.id).first) {
        final item = await menu.getItem(row.id);
        if (item != null) items.add(item);
      }
    }
    return MenuSnapshot(
      categories: categories,
      items: items,
      modifierGroups: await menu.watchModifierGroups().first,
    );
  }

  @override
  Future<void> apply(MenuChangeSet changes) async {
    if (changes.isEmpty) return;
    await _validate(changes);
    await db.transaction(() async {
      for (final category in changes.upsertCategories) {
        await menu.upsertCategory(category);
      }
      for (final item in changes.upsertItems) {
        await menu.upsertItem(item);
      }
      for (final id in changes.deleteItemIds) {
        await menu.deleteItem(id);
      }
    });
  }

  @override
  Future<List<String>> publishMenu() => _publish();

  /// SQLite doesn't enforce foreign keys here, so check what the database
  /// won't: every item needs a real category, a name and a non-negative price.
  Future<void> _validate(MenuChangeSet changes) async {
    final categoryIds = {
      for (final c in await menu.watchCategories().first) c.id,
      for (final c in changes.upsertCategories) c.id,
    };
    for (final c in changes.upsertCategories) {
      if (c.name.trim().isEmpty) {
        throw const MenuChangeRejected('A category needs a name.');
      }
    }
    for (final item in changes.upsertItems) {
      if (!categoryIds.contains(item.categoryId)) {
        throw MenuChangeRejected(
          '"${item.name}" is in a category that does not exist.',
        );
      }
      if (item.name.trim().isEmpty) {
        throw const MenuChangeRejected('An item needs a name.');
      }
      if (item.price.isNegative) {
        throw MenuChangeRejected('"${item.name}" has a negative price.');
      }
    }
  }
}
