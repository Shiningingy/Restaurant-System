import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../../../core/sync/providers.dart';
import '../data/item_image_repository.dart';
import '../data/menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => MenuRepository(
    ref.watch(databaseProvider),
    journal: ref.watch(syncJournalProvider),
  ),
);

final itemImageRepositoryProvider = Provider<ItemImageRepository>(
  (ref) => ItemImageRepository(ref.watch(databaseProvider)),
);

/// Live images for one item — used by the item editor.
final itemImagesProvider = StreamProvider.family<List<ItemImage>, String>(
  (ref, itemId) => ref.watch(itemImageRepositoryProvider).watchImages(itemId),
);

/// One item with attributes + modifier ids hydrated, for the editor.
final itemEditorProvider = FutureProvider.family<domain.MenuItem?, String>(
  (ref, itemId) => ref.watch(menuRepositoryProvider).getItem(itemId),
);

final categoriesProvider = StreamProvider<List<domain.Category>>(
  (ref) => ref.watch(menuRepositoryProvider).watchCategories(),
);

final itemsInCategoryProvider =
    StreamProvider.family<List<domain.MenuItem>, String>(
      (ref, categoryId) =>
          ref.watch(menuRepositoryProvider).watchItemsInCategory(categoryId),
    );

final modifierGroupsProvider = StreamProvider<List<domain.ModifierGroup>>(
  (ref) => ref.watch(menuRepositoryProvider).watchModifierGroups(),
);
