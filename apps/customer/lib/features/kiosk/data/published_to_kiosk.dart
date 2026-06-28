import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

import '../../storefront/data/menu_photo_url.dart';

/// Maps the customer app's [domain.PublishedMenu] into the shared [KioskMenu]
/// the [KioskSurface] renders — so the tablet kiosk looks identical to the
/// merchant's. Prices are formatted the same way the merchant's snapshot does
/// (`Money.format()`), and the second-language-name swap mirrors the menu
/// list, so a 中文 customer sees the second name as the primary line.
///
/// `serviceFeeBp` is 0 and `payHere` is false: customer preorders are
/// pay-at-pickup, and card-at-kiosk isn't wired to a processor yet.
KioskMenu publishedToKioskMenu(
  domain.PublishedMenu menu, {
  required String appLanguageCode,
  String? storefrontUrl,
}) {
  return KioskMenu(
    businessName: menu.restaurantName,
    taxRateBp: menu.taxRateBp,
    serviceFeeBp: 0,
    payHere: false,
    categories: [
      for (final c in menu.categories)
        KioskCategory(
          id: c.id,
          name: c.name,
          items: [
            for (final it in c.items)
              _item(
                it,
                menu.secondNameLanguage,
                appLanguageCode,
                storefrontUrl,
              ),
          ],
        ),
    ],
  );
}

KioskItem _item(
  domain.PublishedItem it,
  String? secondLang,
  String appLang,
  String? storefrontUrl,
) {
  final second = it.nameSecondary;
  // Same rule as the menu list: when the app language matches the merchant's
  // second-name language, show the second name as the primary line.
  final swap =
      secondLang != null &&
      secondLang.isNotEmpty &&
      second != null &&
      second.isNotEmpty &&
      appLang == secondLang;
  return KioskItem(
    id: it.id,
    code: null,
    name: swap ? second : it.name,
    nameSecondary: swap ? it.name : second,
    description: it.description,
    priceCents: it.price.cents,
    price: it.price.format(),
    imageUrl: menuPhotoUrl(storefrontUrl, it),
    modifierGroups: [
      for (final g in it.modifierGroups)
        KioskModifierGroup(
          id: g.id,
          name: g.name,
          minSelect: g.minSelect,
          maxSelect: g.maxSelect,
          modifiers: [
            for (final m in g.modifiers)
              KioskModifier(
                id: m.id,
                name: m.name,
                deltaCents: m.priceDelta.cents,
                delta: m.priceDelta.format(),
              ),
          ],
        ),
    ],
  );
}
