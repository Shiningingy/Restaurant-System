import 'package:crypto/crypto.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../menu/data/menu_repository.dart';
import '../../../core/settings/settings_repository.dart';

/// An item's photo bytes + file extension, for publishing.
typedef ItemPhoto = ({List<int> bytes, String ext});

/// Builds the [domain.PublishedMenu] the customer app browses, from the
/// merchant's live menu. Only active categories and items are published.
class MenuPublisher {
  final MenuRepository menu;
  final SettingsRepository settings;

  /// Reads an item's primary photo (bytes + extension), or null when it has
  /// none. Supplied so the publisher can upload item photos for the customer.
  final Future<ItemPhoto?> Function(String itemId)? itemPhoto;

  /// Public Storage bucket the item photos are uploaded to (content-addressed
  /// as `<sha><ext>`). Null = don't publish photos (cloud off / no store).
  final domain.ObjectStore? photoStore;

  MenuPublisher({
    required this.menu,
    required this.settings,
    this.itemPhoto,
    this.photoStore,
  });

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
        final (imageSha, imageExt) = await _publishPhoto(item.id);
        published.add(
          domain.PublishedItem(
            id: item.id,
            name: item.name,
            nameSecondary: item.nameSecondary,
            description: item.description,
            price: item.price,
            imageSha: imageSha,
            imageExt: imageExt,
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
      pickupLeadMinutes: settings.pickupLeadMinutes,
      taxRateBp: settings.taxRateBp,
      secondNameLanguage: settings.secondNameLanguage,
      acceptsOnlinePayment: settings.acceptsOnlinePayment,
      categories: categories,
    );
  }

  /// Uploads the item's photo to the public bucket (content-addressed) and
  /// returns its `(sha, ext)` ref, or `(null, null)` when there's no photo or
  /// no cloud. Best-effort — a failed upload just ships the item without a
  /// photo, never failing the publish.
  Future<(String?, String?)> _publishPhoto(String itemId) async {
    final store = photoStore;
    final read = itemPhoto;
    if (store == null || read == null) return (null, null);
    try {
      final photo = await read(itemId);
      if (photo == null) return (null, null);
      final sha = sha256.convert(photo.bytes).toString();
      await store.putObject(
        '$sha${photo.ext}',
        photo.bytes,
        contentType: _contentType(photo.ext),
      );
      return (sha, photo.ext);
    } on Object {
      return (null, null);
    }
  }

  static String _contentType(String ext) => switch (ext.toLowerCase()) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.gif' => 'image/gif',
    _ => 'application/octet-stream',
  };
}
