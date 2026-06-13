import 'package:customer/features/cart/cart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

void main() {
  const burger = domain.PublishedItem(
    id: 'i1',
    name: 'Burger',
    price: domain.Money(1000),
    modifierGroups: [],
  );
  const large = domain.PublishedModifier(
    id: 'm1',
    name: 'Large',
    priceDelta: domain.Money(200),
  );

  test('line total includes modifier deltas times quantity', () {
    const line = CartLine(item: burger, modifiers: [large], qty: 3);
    expect(line.unitPrice, const domain.Money(1200));
    expect(line.lineTotal, const domain.Money(3600));
  });

  test('cart sums lines and counts items', () {
    const cart = Cart(
      lines: [
        CartLine(item: burger, modifiers: [large], qty: 2), // 2400
        CartLine(item: burger, qty: 1), // 1000
      ],
    );
    expect(cart.total, const domain.Money(3400));
    expect(cart.itemCount, 3);
    expect(cart.isEmpty, isFalse);
  });

  test('a cart line converts to a preorder line with snapshots', () {
    const line = CartLine(item: burger, modifiers: [large], qty: 2);
    final pre = line.toPreorderLine();
    expect(pre.itemId, 'i1');
    expect(pre.nameSnapshot, 'Burger');
    expect(pre.priceSnapshot, const domain.Money(1000));
    expect(pre.qty, 2);
    expect(pre.modifiers.single.nameSnapshot, 'Large');
    expect(pre.lineTotal, const domain.Money(2400));
  });
}
