import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// One line in the customer's cart: an item, the modifiers they chose,
/// and a quantity.
class CartLine {
  final domain.PublishedItem item;
  final List<domain.PublishedModifier> modifiers;
  final int qty;

  const CartLine({required this.item, this.modifiers = const [], this.qty = 1});

  domain.Money get unitPrice {
    var price = item.price;
    for (final m in modifiers) {
      price += m.priceDelta;
    }
    return price;
  }

  domain.Money get lineTotal => unitPrice * qty;

  CartLine withQty(int newQty) =>
      CartLine(item: item, modifiers: modifiers, qty: newQty);

  domain.PreorderLine toPreorderLine() => domain.PreorderLine(
    itemId: item.id,
    nameSnapshot: item.name,
    priceSnapshot: item.price,
    qty: qty,
    modifiers: [
      for (final m in modifiers)
        domain.PreorderModifier(
          nameSnapshot: m.name,
          priceDeltaSnapshot: m.priceDelta,
        ),
    ],
  );
}

class Cart {
  final List<CartLine> lines;

  const Cart({this.lines = const []});

  domain.Money get total =>
      lines.fold(domain.Money.zero, (sum, l) => sum + l.lineTotal);

  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);

  bool get isEmpty => lines.isEmpty;
}

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() => const Cart();

  void add(CartLine line) {
    state = Cart(lines: [...state.lines, line]);
  }

  void setQty(int index, int qty) {
    if (qty < 1) return removeAt(index);
    final lines = [...state.lines];
    lines[index] = lines[index].withQty(qty);
    state = Cart(lines: lines);
  }

  void removeAt(int index) {
    final lines = [...state.lines]..removeAt(index);
    state = Cart(lines: lines);
  }

  void clear() => state = const Cart();
}

final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);
