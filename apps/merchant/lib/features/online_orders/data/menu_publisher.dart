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

  /// Items whose photo couldn't be uploaded on the last [build] — one
  /// human-readable line each (e.g. the bucket is missing or RLS rejected the
  /// write). A photo that simply doesn't exist locally is NOT an error and is
  /// never listed. Reset at the start of every [build].
  final List<String> photoErrors = [];

  Future<domain.PublishedMenu> build() async {
    photoErrors.clear();
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
      tipPresetsBp: settings.tipPresetsBp,
      categories: categories,
    );
  }

  /// Uploads the item's photo to the public bucket (content-addressed) and
  /// returns its `(sha, ext)` ref, or `(null, null)` when there's no photo or
  /// no cloud. Never fails the publish — but, unlike a missing photo, a genuine
  /// read/upload failure is recorded in [photoErrors] so it's visible (a silent
  /// upload failure looks identical to "no photo": the item just ships without
  /// one). We only return the ref once the bytes are actually in the bucket, so
  /// the customer never points at an object that isn't there.
  Future<(String?, String?)> _publishPhoto(String itemId) async {
    final store = photoStore;
    final read = itemPhoto;
    if (store == null || read == null) return (null, null);
    final ItemPhoto? photo;
    try {
      photo = await read(itemId);
    } on Object catch (e) {
      photoErrors.add('item $itemId: could not read its photo — $e');
      return (null, null);
    }
    if (photo == null) return (null, null); // no photo is not an error
    final sha = sha256.convert(photo.bytes).toString();
    try {
      await store.putObject(
        '$sha${photo.ext}',
        photo.bytes,
        contentType: _contentType(photo.ext),
      );
    } on Object catch (e) {
      photoErrors.add('item $itemId: photo upload failed — $e');
      return (null, null);
    }
    return (sha, photo.ext);
  }

  static String _contentType(String ext) => switch (ext.toLowerCase()) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.gif' => 'image/gif',
    _ => 'application/octet-stream',
  };
}
