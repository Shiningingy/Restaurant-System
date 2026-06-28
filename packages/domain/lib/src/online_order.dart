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

  /// Optional longer description (ingredients, notes) shown under the item.
  final String? description;
  final Money price;
  final List<PublishedModifierGroup> modifierGroups;

  /// Content-addressed photo reference (sha256 of the bytes + extension), or
  /// null when the item has no photo. The customer builds a public Storage URL
  /// from it (`menu-photos/<sha><ext>`) — see docs/CLOUD_SECURITY.md.
  final String? imageSha;
  final String? imageExt;

  const PublishedItem({
    required this.id,
    required this.name,
    required this.price,
    this.nameSecondary,
    this.description,
    this.modifierGroups = const [],
    this.imageSha,
    this.imageExt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (nameSecondary != null) 'nameSecondary': nameSecondary,
        if (description != null) 'description': description,
        'price': price.cents,
        'modifierGroups': modifierGroups.map((g) => g.toJson()).toList(),
        if (imageSha != null) 'imageSha': imageSha,
        if (imageExt != null) 'imageExt': imageExt,
      };

  factory PublishedItem.fromJson(Map<String, dynamic> j) => PublishedItem(
        id: j['id'] as String,
        name: j['name'] as String,
        nameSecondary: j['nameSecondary'] as String?,
        description: j['description'] as String?,
        price: Money(j['price'] as int),
        modifierGroups: (j['modifierGroups'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PublishedModifierGroup.fromJson)
            .toList(),
        imageSha: j['imageSha'] as String?,
        imageExt: j['imageExt'] as String?,
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

  /// Soonest the customer may request pickup, in minutes from now. The
  /// customer app enforces this so it never asks for an impossible time.
  /// Defaults to 0 for menus published before this field existed.
  final int pickupLeadMinutes;

  /// The restaurant's tax rate in basis points (e.g. 1300 = 13%), so the
  /// customer app can show an *estimated* tax + total before pickup. The
  /// merchant still applies tax authoritatively on its side. 0 if unpublished.
  final int taxRateBp;

  /// The language code (e.g. 'zh') the item second names are written in, set by
  /// the merchant. When the customer's app language matches, the second name is
  /// shown as the primary line. Null/empty → just stack both, name first.
  final String? secondNameLanguage;

  /// True when the merchant has enabled online card payment (and deployed the
  /// pay-online Edge Function). The customer app only offers "Pay online" when
  /// this is set; otherwise preorders are pay-at-pickup. Defaults to off.
  final bool acceptsOnlinePayment;

  /// Suggested tip percentages (basis points) the customer can pick at the
  /// kiosk / online checkout — e.g. [0, 1000, 1500, 2000] = No tip / 10 / 15 /
  /// 20%. Up to 4; a 0 entry renders as "No tip". Percentages are of the
  /// pre-tax subtotal. Empty = no tip selector shown. Defaults to empty for
  /// menus published before this field existed.
  final List<int> tipPresetsBp;

  const PublishedMenu({
    required this.restaurantName,
    required this.categories,
    this.pickupLeadMinutes = 0,
    this.taxRateBp = 0,
    this.secondNameLanguage,
    this.acceptsOnlinePayment = false,
    this.tipPresetsBp = const [],
  });

  Map<String, dynamic> toJson() => {
        'restaurantName': restaurantName,
        'pickupLeadMinutes': pickupLeadMinutes,
        'taxRateBp': taxRateBp,
        if (secondNameLanguage != null)
          'secondNameLanguage': secondNameLanguage,
        if (acceptsOnlinePayment) 'acceptsOnlinePayment': true,
        if (tipPresetsBp.isNotEmpty) 'tipPresetsBp': tipPresetsBp,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  factory PublishedMenu.fromJson(Map<String, dynamic> j) => PublishedMenu(
        restaurantName: j['restaurantName'] as String? ?? '',
        pickupLeadMinutes: j['pickupLeadMinutes'] as int? ?? 0,
        taxRateBp: j['taxRateBp'] as int? ?? 0,
        secondNameLanguage: j['secondNameLanguage'] as String?,
        acceptsOnlinePayment: j['acceptsOnlinePayment'] as bool? ?? false,
        tipPresetsBp:
            (j['tipPresetsBp'] as List?)?.map((e) => e as int).toList() ??
                const [],
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
  final String? customerEmail;

  /// How the customer wants to hear the order is ready. Carried on the order
  /// so the restaurant's notify Edge Function knows whether/where to send
  /// (it never sends unless asked). Defaults to off.
  final bool notifyByEmail;
  final bool notifyBySms;
  final DateTime requestedPickupAt;
  final List<PreorderLine> lines;
  final String? note;

  /// True when this preorder was placed at an in-store self-order **kiosk**
  /// (not a remote customer). The merchant can auto-accept these straight to
  /// the Orders board, since the customer is already on site.
  final bool kiosk;

  const PreorderSubmission({
    required this.customerName,
    required this.requestedPickupAt,
    required this.lines,
    this.customerPhone,
    this.customerEmail,
    this.notifyByEmail = false,
    this.notifyBySms = false,
    this.note,
    this.kiosk = false,
  });

  Money get total => lines.fold(Money.zero, (sum, l) => sum + l.lineTotal);

  Map<String, dynamic> toJson() => {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'notifyByEmail': notifyByEmail,
        'notifyBySms': notifyBySms,
        'requestedPickupAt': requestedPickupAt.toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'note': note,
        'kiosk': kiosk,
      };

  factory PreorderSubmission.fromJson(Map<String, dynamic> j) =>
      PreorderSubmission(
        customerName: j['customerName'] as String,
        customerPhone: j['customerPhone'] as String?,
        customerEmail: j['customerEmail'] as String?,
        notifyByEmail: j['notifyByEmail'] as bool? ?? false,
        notifyBySms: j['notifyBySms'] as bool? ?? false,
        requestedPickupAt: DateTime.parse(j['requestedPickupAt'] as String),
        lines: (j['lines'] as List)
            .cast<Map<String, dynamic>>()
            .map(PreorderLine.fromJson)
            .toList(),
        note: j['note'] as String?,
        kiosk: j['kiosk'] as bool? ?? false,
      );
}
