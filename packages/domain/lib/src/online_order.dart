/// Shared wire model for online preordering (Phase 6).
///
/// These types are the contract between the customer app (which browses a
/// [PublishedMenu] and submits a [PreorderSubmission]) and the merchant
/// tablet (which receives it). They live in the pure-Dart domain package
/// so both apps serialize identically; the transport that carries the
/// JSON lives in each app's drivers.
library;

import 'money.dart';

/// Table names in the restaurant's Supabase that carry online ordering.
/// Shared so the customer client and merchant channel never disagree.
class OnlineOrderingTables {
  static const publishedMenu = 'published_menu';
  static const onlineOrders = 'online_orders';
}

class PublishedModifier {
  final String id;
  final String name;
  final Money priceDelta;

  const PublishedModifier({
    required this.id,
    required this.name,
    required this.priceDelta,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceDelta': priceDelta.cents,
      };

  factory PublishedModifier.fromJson(Map<String, dynamic> j) =>
      PublishedModifier(
        id: j['id'] as String,
        name: j['name'] as String,
        priceDelta: Money(j['priceDelta'] as int),
      );
}

class PublishedModifierGroup {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<PublishedModifier> modifiers;

  const PublishedModifierGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.modifiers,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'minSelect': minSelect,
        'maxSelect': maxSelect,
        'modifiers': modifiers.map((m) => m.toJson()).toList(),
      };

  factory PublishedModifierGroup.fromJson(Map<String, dynamic> j) =>
      PublishedModifierGroup(
        id: j['id'] as String,
        name: j['name'] as String,
        minSelect: j['minSelect'] as int,
        maxSelect: j['maxSelect'] as int,
        modifiers: (j['modifiers'] as List)
            .cast<Map<String, dynamic>>()
            .map(PublishedModifier.fromJson)
            .toList(),
      );
}

class PublishedItem {
  final String id;
  final String name;

  /// Optional second-language name (e.g. 中文) shown to customers who switch
  /// the app language. Null when the merchant's menu has no second name.
  final String? nameSecondary;
  final Money price;
  final List<PublishedModifierGroup> modifierGroups;

  const PublishedItem({
    required this.id,
    required this.name,
    required this.price,
    this.nameSecondary,
    this.modifierGroups = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (nameSecondary != null) 'nameSecondary': nameSecondary,
        'price': price.cents,
        'modifierGroups': modifierGroups.map((g) => g.toJson()).toList(),
      };

  factory PublishedItem.fromJson(Map<String, dynamic> j) => PublishedItem(
        id: j['id'] as String,
        name: j['name'] as String,
        nameSecondary: j['nameSecondary'] as String?,
        price: Money(j['price'] as int),
        modifierGroups: (j['modifierGroups'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PublishedModifierGroup.fromJson)
            .toList(),
      );
}

class PublishedCategory {
  final String id;
  final String name;
  final List<PublishedItem> items;

  const PublishedCategory({
    required this.id,
    required this.name,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory PublishedCategory.fromJson(Map<String, dynamic> j) =>
      PublishedCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        items: (j['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(PublishedItem.fromJson)
            .toList(),
      );
}

/// The whole menu the customer app browses, as published by the merchant.
class PublishedMenu {
  final String restaurantName;
  final List<PublishedCategory> categories;

  const PublishedMenu({required this.restaurantName, required this.categories});

  Map<String, dynamic> toJson() => {
        'restaurantName': restaurantName,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  factory PublishedMenu.fromJson(Map<String, dynamic> j) => PublishedMenu(
        restaurantName: j['restaurantName'] as String? ?? '',
        categories: (j['categories'] as List)
            .cast<Map<String, dynamic>>()
            .map(PublishedCategory.fromJson)
            .toList(),
      );
}

class PreorderModifier {
  final String nameSnapshot;
  final Money priceDeltaSnapshot;

  const PreorderModifier({
    required this.nameSnapshot,
    required this.priceDeltaSnapshot,
  });

  Map<String, dynamic> toJson() => {
        'nameSnapshot': nameSnapshot,
        'priceDeltaSnapshot': priceDeltaSnapshot.cents,
      };

  factory PreorderModifier.fromJson(Map<String, dynamic> j) => PreorderModifier(
        nameSnapshot: j['nameSnapshot'] as String,
        priceDeltaSnapshot: Money(j['priceDeltaSnapshot'] as int),
      );
}

class PreorderLine {
  final String itemId;
  final String nameSnapshot;
  final Money priceSnapshot;
  final int qty;
  final List<PreorderModifier> modifiers;
  final String? note;

  const PreorderLine({
    required this.itemId,
    required this.nameSnapshot,
    required this.priceSnapshot,
    required this.qty,
    this.modifiers = const [],
    this.note,
  });

  /// Unit price including modifier deltas, times quantity.
  Money get lineTotal {
    var unit = priceSnapshot;
    for (final m in modifiers) {
      unit += m.priceDeltaSnapshot;
    }
    return unit * qty;
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'nameSnapshot': nameSnapshot,
        'priceSnapshot': priceSnapshot.cents,
        'qty': qty,
        'modifiers': modifiers.map((m) => m.toJson()).toList(),
        'note': note,
      };

  factory PreorderLine.fromJson(Map<String, dynamic> j) => PreorderLine(
        itemId: j['itemId'] as String,
        nameSnapshot: j['nameSnapshot'] as String,
        priceSnapshot: Money(j['priceSnapshot'] as int),
        qty: j['qty'] as int,
        modifiers: (j['modifiers'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PreorderModifier.fromJson)
            .toList(),
        note: j['note'] as String?,
      );
}

/// A preorder the customer submits — pickup, pay at store. No payment
/// data ever travels with it (docs/PRINCIPLES.md).
class PreorderSubmission {
  final String customerName;
  final String? customerPhone;
  final DateTime requestedPickupAt;
  final List<PreorderLine> lines;
  final String? note;

  const PreorderSubmission({
    required this.customerName,
    required this.requestedPickupAt,
    required this.lines,
    this.customerPhone,
    this.note,
  });

  Money get total => lines.fold(Money.zero, (sum, l) => sum + l.lineTotal);

  Map<String, dynamic> toJson() => {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'requestedPickupAt': requestedPickupAt.toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'note': note,
      };

  factory PreorderSubmission.fromJson(Map<String, dynamic> j) =>
      PreorderSubmission(
        customerName: j['customerName'] as String,
        customerPhone: j['customerPhone'] as String?,
        requestedPickupAt: DateTime.parse(j['requestedPickupAt'] as String),
        lines: (j['lines'] as List)
            .cast<Map<String, dynamic>>()
            .map(PreorderLine.fromJson)
            .toList(),
        note: j['note'] as String?,
      );
}
