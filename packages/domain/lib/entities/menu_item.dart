import 'package:freezed_annotation/freezed_annotation.dart';

import '../src/money.dart';

part 'menu_item.freezed.dart';

@freezed
abstract class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String id,
    required String categoryId,
    required String name,
    required Money price,
    String? sku,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,

    /// Ids of the modifier groups offered with this item
    /// (filled by the repository from the join table).
    @Default([]) List<String> modifierGroupIds,
  }) = _MenuItem;
}
