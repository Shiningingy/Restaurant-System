import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../menu/data/menu_repository.dart';
import '../../../core/settings/settings_repository.dart';

/// Builds the [domain.PublishedMenu] the customer app browses, from the
/// merchant's live menu. Only active categories and items are published.
class MenuPublisher {
  final MenuRepository menu;
  final SettingsRepository settings;

  MenuPublisher({required this.menu, required this.settings});

  Future<domain.PublishedMenu> build() async {
    final categories = <domain.PublishedCategory>[];
    final cats = (await menu.watchCategories().first)
        .where((c) => c.isActive)
        .toList();
    for (final cat in cats) {
      final items = (await menu.watchItemsInCategory(cat.id).first)
          .where((i) => i.isActive)
          .toList();
      final published = <domain.PublishedItem>[];
      for (final item in items) {
        final groups = await menu.getModifierGroupsForItem(item.id);
        published.add(
          domain.PublishedItem(
            id: item.id,
            name: item.name,
            price: item.price,
            modifierGroups: [
              for (final g in groups)
                domain.PublishedModifierGroup(
                  id: g.id,
                  name: g.name,
                  minSelect: g.minSelect,
                  maxSelect: g.maxSelect,
                  modifiers: [
                    for (final m in g.modifiers)
                      domain.PublishedModifier(
                        id: m.id,
                        name: m.name,
                        priceDelta: m.priceDelta,
                      ),
                  ],
                ),
            ],
          ),
        );
      }
      if (published.isNotEmpty) {
        categories.add(
          domain.PublishedCategory(
            id: cat.id,
            name: cat.name,
            items: published,
          ),
        );
      }
    }
    return domain.PublishedMenu(
      restaurantName: settings.receiptConfig.businessName,
      categories: categories,
    );
  }
}
