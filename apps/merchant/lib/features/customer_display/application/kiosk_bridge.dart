import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../menu/data/menu_repository.dart';
import '../../orders/data/order_repository.dart';

/// Pure bridge logic for the kiosk, decoupled from Riverpod and the window
/// channel so it can be unit-tested against a real (in-memory) database. The
/// controller wires these to the channel; everything here is plain repo calls.

/// Serializes the live menu (active categories → active items → modifier
/// groups) into the small JSON tree the kiosk window renders. Prices carry both
/// cents (for the kiosk's running total) and a formatted string (for display).
/// Categories with no active items are omitted.
Future<Map<String, dynamic>> buildKioskMenuSnapshot(
  MenuRepository menu, {
  required String businessName,
}) async {
  final categories = await menu.watchCategories().first;
  final cats = <Map<String, dynamic>>[];
  for (final c in categories.where((c) => c.isActive)) {
    final items = await menu.watchItemsInCategory(c.id).first;
    final itemList = <Map<String, dynamic>>[];
    for (final it in items.where((i) => i.isActive)) {
      final groups = await menu.getModifierGroupsForItem(it.id);
      itemList.add({
        'id': it.id,
        'code': it.code,
        'name': it.name,
        'nameSecondary': it.nameSecondary,
        'description': it.description,
        'priceCents': it.price.cents,
        'price': it.price.format(),
        'modifierGroups': [
          for (final g in groups)
            {
              'id': g.id,
              'name': g.name,
              'minSelect': g.minSelect,
              'maxSelect': g.maxSelect,
              'modifiers': [
                for (final m in g.modifiers)
                  {
                    'id': m.id,
                    'name': m.name,
                    'deltaCents': m.priceDelta.cents,
                    'delta': m.priceDelta.format(),
                  },
              ],
            },
        ],
      });
    }
    if (itemList.isNotEmpty) {
      cats.add({'id': c.id, 'name': c.name, 'items': itemList});
    }
  }
  return {'businessName': businessName, 'categories': cats};
}

/// Turns a cart the customer built in the kiosk window into a real local order
/// (type takeout, pay-at-counter). Prices, names and modifiers are re-read from
/// the current menu — the kiosk's numbers are never trusted. The order is
/// written through [orders]' own connection so it lands on the POS order board
/// live. Returns `{ok, orderId, code}`; `{ok:false}` if the cart is empty.
///
/// Each cart line is `{itemId, qty, modifierIds:[...]}`. Items or modifiers
/// removed since the menu was pushed are skipped rather than failing the order.
Future<Map<String, dynamic>> registerKioskOrder({
  required MenuRepository menu,
  required OrderRepository orders,
  required int taxRateBp,
  required int serviceFeeBp,
  required List<Map<String, dynamic>> lines,
}) async {
  if (lines.isEmpty) return {'ok': false};

  final orderId = await orders.createOrder(
    type: domain.OrderType.takeout,
    taxRateBp: taxRateBp,
    serviceFeeBp: serviceFeeBp,
    note: 'Kiosk',
  );

  for (final line in lines) {
    final item = await menu.getItem(line['itemId'] as String);
    if (item == null) continue; // item removed since the menu was pushed
    final wantedIds = ((line['modifierIds'] as List?) ?? const [])
        .cast<String>()
        .toSet();
    final groups = await menu.getModifierGroupsForItem(item.id);
    final selected = [
      for (final g in groups)
        for (final m in g.modifiers)
          if (wantedIds.contains(m.id)) m,
    ];
    await orders.addLine(
      orderId: orderId,
      item: item,
      selectedModifiers: selected,
      qty: (line['qty'] as num?)?.toInt() ?? 1,
    );
  }

  return {
    'ok': true,
    'orderId': orderId,
    // A short, human-friendly pickup code derived from the order id.
    'code': orderId.replaceAll('-', '').substring(0, 4).toUpperCase(),
  };
}
