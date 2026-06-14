import 'package:restaurant_domain/restaurant_domain.dart';

import 'geometry.dart';

/// A menu item extracted from one placement of the capture template, before the
/// merchant reviews/edits and saves it. Mutable so the review screen can tweak
/// fields in place. `imageBoxes` are absolute regions in the source photo to be
/// cropped into the item's photos at save time.
class ItemDraft {
  String? code;
  String? name;
  String? nameSecondary;
  Money? price;
  final List<MenuItemAttribute> attributes;
  final List<PixelBox> imageBoxes;

  ItemDraft({
    this.code,
    this.name,
    this.nameSecondary,
    this.price,
    List<MenuItemAttribute>? attributes,
    List<PixelBox>? imageBoxes,
  }) : attributes = attributes ?? [],
       imageBoxes = imageBoxes ?? [];

  /// Whether the draft captured anything worth keeping (otherwise the placement
  /// landed on empty space and can be dropped).
  bool get isEmpty =>
      (code == null || code!.isEmpty) &&
      (name == null || name!.isEmpty) &&
      (nameSecondary == null || nameSecondary!.isEmpty) &&
      price == null &&
      attributes.isEmpty &&
      imageBoxes.isEmpty;
}
