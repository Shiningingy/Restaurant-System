import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item_attribute.freezed.dart';

/// A user-defined, renamable text field on a menu item (e.g. Description,
/// Ingredients, Allergens). The merchant adds/labels these at runtime, so the
/// field set isn't fixed in the schema. Carried as part of the menu_item
/// aggregate and synced with it.
@freezed
abstract class MenuItemAttribute with _$MenuItemAttribute {
  const factory MenuItemAttribute({
    required String id,
    required String label,
    required String value,
    @Default(0) int sortOrder,
  }) = _MenuItemAttribute;
}
