import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

void main() {
  group('PublishedItem second-language name', () {
    test('round-trips the optional nameSecondary', () {
      const item = PublishedItem(
        id: 'i1',
        name: 'Unagi poke',
        nameSecondary: '鳗鱼波奇饭',
        price: Money(1399),
      );

      final back = PublishedItem.fromJson(item.toJson());

      expect(back.name, 'Unagi poke');
      expect(back.nameSecondary, '鳗鱼波奇饭');
      expect(back.price, const Money(1399));
    });

    test('omits nameSecondary from JSON when absent', () {
      const item = PublishedItem(id: 'i1', name: 'Fries', price: Money(500));
      expect(item.toJson().containsKey('nameSecondary'), isFalse);
      expect(PublishedItem.fromJson(item.toJson()).nameSecondary, isNull);
    });

    test('parses older payloads that predate nameSecondary', () {
      // A menu published before the field existed has no key at all.
      final legacy = {
        'id': 'i1',
        'name': 'Fries',
        'price': 500,
        'modifierGroups': <dynamic>[],
      };
      expect(PublishedItem.fromJson(legacy).nameSecondary, isNull);
    });

    test('survives a whole-menu round-trip', () {
      const menu = PublishedMenu(
        restaurantName: 'Yee Sushi',
        categories: [
          PublishedCategory(
            id: 'c1',
            name: 'Poke',
            items: [
              PublishedItem(
                id: 'i1',
                name: 'Salmon poke',
                nameSecondary: '三文鱼波奇饭',
                price: Money(1399),
              ),
            ],
          ),
        ],
      );

      final back = PublishedMenu.fromJson(menu.toJson());
      expect(back.categories.single.items.single.nameSecondary, '三文鱼波奇饭');
    });
  });

  group('PublishedMenu online payment flag', () {
    test('defaults off and is omitted from JSON', () {
      const menu = PublishedMenu(restaurantName: 'Diner', categories: []);
      expect(menu.acceptsOnlinePayment, isFalse);
      expect(menu.toJson().containsKey('acceptsOnlinePayment'), isFalse);
    });

    test('round-trips when enabled', () {
      const menu = PublishedMenu(
        restaurantName: 'Diner',
        categories: [],
        acceptsOnlinePayment: true,
      );
      expect(
          PublishedMenu.fromJson(menu.toJson()).acceptsOnlinePayment, isTrue);
    });

    test('older payloads without the key parse as off', () {
      final legacy = {
        'restaurantName': 'Diner',
        'categories': <dynamic>[],
      };
      expect(PublishedMenu.fromJson(legacy).acceptsOnlinePayment, isFalse);
    });
  });

  group('PublishedMenu tip presets', () {
    test('default empty is omitted from JSON', () {
      const menu = PublishedMenu(restaurantName: 'Diner', categories: []);
      expect(menu.tipPresetsBp, isEmpty);
      expect(menu.toJson().containsKey('tipPresetsBp'), isFalse);
    });

    test('round-trips the presets', () {
      const menu = PublishedMenu(
        restaurantName: 'Diner',
        categories: [],
        tipPresetsBp: [0, 1000, 1500, 2000],
      );
      expect(
        PublishedMenu.fromJson(menu.toJson()).tipPresetsBp,
        [0, 1000, 1500, 2000],
      );
    });
  });

  group('PreorderSubmission tip', () {
    final base = PreorderSubmission(
      customerName: 'Sam',
      requestedPickupAt: DateTime.utc(2026, 6, 28, 18),
      lines: const [
        PreorderLine(
          itemId: 'i1',
          nameSnapshot: 'Ramen',
          priceSnapshot: Money(1200),
          qty: 1,
        ),
      ],
    );

    test('defaults to zero and is omitted from JSON', () {
      expect(base.tip, Money.zero);
      expect(base.toJson().containsKey('tip'), isFalse);
    });

    test('round-trips a chosen tip in cents', () {
      final back = PreorderSubmission.fromJson(
        PreorderSubmission(
          customerName: base.customerName,
          requestedPickupAt: base.requestedPickupAt,
          lines: base.lines,
          tip: const Money(300),
        ).toJson(),
      );
      expect(back.tip, const Money(300));
    });
  });
}
