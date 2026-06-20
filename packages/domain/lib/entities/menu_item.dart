import 'package:freezed_annotation/freezed_annotation.dart';

import '../src/money.dart';
import 'menu_item_attribute.dart';

part 'menu_item.freezed.dart';

@freezed
abstract class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String id,
    required String categoryId,
    required String name,
    required Money price,

    /// Optional human item number (e.g. "A01") for ordering "by number".
    /// Distinct from [sortOrder], which is the internal display order.
    String? code,

    /// Optional second name line (e.g. a native-language name), shown stacked
    /// under [name]. Language-agnostic — both lines always show together.
    String? nameSecondary,

    /// Optional longer description (ingredients, notes) shown on the menu.
    String? description,
    String? sku,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,

    /// Ids of the modifier groups offered with this item
    /// (filled by the repository from the join table).
    @Default([]) List<String> modifierGroupIds,

    /// User-defined renamable text fields (filled by the repository).
    @Default([]) List<MenuItemAttribute> attributes,
  }) = _MenuItem;
}
