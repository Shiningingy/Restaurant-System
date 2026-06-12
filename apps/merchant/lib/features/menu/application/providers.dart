import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../data/menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => MenuRepository(ref.watch(databaseProvider)),
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
