import 'package:customer/features/kiosk/data/published_to_kiosk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

void main() {
  domain.PublishedMenu menu({String? secondLang}) => domain.PublishedMenu(
    restaurantName: 'Yee Sushi',
    taxRateBp: 1300,
    secondNameLanguage: secondLang,
    categories: [
      domain.PublishedCategory(
        id: 'c1',
        name: 'Rolls',
        items: [
          domain.PublishedItem(
            id: 'i1',
            name: 'Salmon Roll',
            nameSecondary: '三文鱼卷',
            price: const domain.Money(1200),
            modifierGroups: const [
              domain.PublishedModifierGroup(
                id: 'g1',
                name: 'Size',
                minSelect: 1,
                maxSelect: 1,
                modifiers: [
                  domain.PublishedModifier(
                    id: 'm1',
                    name: 'Large',
                    priceDelta: domain.Money(200),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  test('maps fields, prices and modifiers the same way the merchant does', () {
    final k = publishedToKioskMenu(menu(), appLanguageCode: 'en');
    expect(k.businessName, 'Yee Sushi');
    expect(k.taxRateBp, 1300);
    expect(k.serviceFeeBp, 0); // no service fee on customer preorders
    expect(k.payHere, isFalse);
    final item = k.categories.single.items.single;
    expect(item.name, 'Salmon Roll');
    expect(item.nameSecondary, '三文鱼卷');
    expect(item.priceCents, 1200);
    expect(item.price, const domain.Money(1200).format());
    final mod = item.modifierGroups.single.modifiers.single;
    expect(mod.deltaCents, 200);
    expect(mod.delta, const domain.Money(200).format());
  });

  test('promotes the second name when the app language matches', () {
    final k = publishedToKioskMenu(
      menu(secondLang: 'zh'),
      appLanguageCode: 'zh',
    );
    final item = k.categories.single.items.single;
    expect(item.name, '三文鱼卷');
    expect(item.nameSecondary, 'Salmon Roll');
  });

  test('keeps the primary name when languages differ', () {
    final k = publishedToKioskMenu(
      menu(secondLang: 'zh'),
      appLanguageCode: 'en',
    );
    final item = k.categories.single.items.single;
    expect(item.name, 'Salmon Roll');
    expect(item.nameSecondary, '三文鱼卷');
  });
}
