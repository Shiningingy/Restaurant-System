/// Lightweight, presentation-only menu model for the kiosk sub-window. It owns
/// no database — these are plain value objects parsed from the JSON the POS
/// window pushes over the customer-display channel. Prices keep cents (for the
/// running cart total) and a pre-formatted string (for display).
class KioskMenu {
  final String businessName;
  final List<KioskCategory> categories;

  const KioskMenu({required this.businessName, required this.categories});

  static KioskMenu fromJson(Map<String, dynamic> j) => KioskMenu(
    businessName: j['businessName'] as String? ?? '',
    categories: ((j['categories'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(KioskCategory.fromJson)
        .toList(),
  );

  bool get isEmpty => categories.isEmpty;
}

class KioskCategory {
  final String id;
  final String name;
  final List<KioskItem> items;

  const KioskCategory({
    required this.id,
    required this.name,
    required this.items,
  });

  static KioskCategory fromJson(Map<String, dynamic> j) => KioskCategory(
    id: j['id'] as String,
    name: j['name'] as String,
    items: ((j['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(KioskItem.fromJson)
        .toList(),
  );
}

class KioskItem {
  final String id;
  final String? code;
  final String name;
  final String? nameSecondary;
  final String? description;
  final int priceCents;
  final String price;
  final List<KioskModifierGroup> modifierGroups;

  const KioskItem({
    required this.id,
    required this.code,
    required this.name,
    required this.nameSecondary,
    required this.description,
    required this.priceCents,
    required this.price,
    required this.modifierGroups,
  });

  static KioskItem fromJson(Map<String, dynamic> j) => KioskItem(
    id: j['id'] as String,
    code: j['code'] as String?,
    name: j['name'] as String,
    nameSecondary: j['nameSecondary'] as String?,
    description: j['description'] as String?,
    priceCents: (j['priceCents'] as num).toInt(),
    price: j['price'] as String,
    modifierGroups: ((j['modifierGroups'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(KioskModifierGroup.fromJson)
        .toList(),
  );

  bool get hasModifiers => modifierGroups.isNotEmpty;
}

class KioskModifierGroup {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<KioskModifier> modifiers;

  const KioskModifierGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.modifiers,
  });

  static KioskModifierGroup fromJson(Map<String, dynamic> j) =>
      KioskModifierGroup(
        id: j['id'] as String,
        name: j['name'] as String,
        minSelect: (j['minSelect'] as num?)?.toInt() ?? 0,
        maxSelect: (j['maxSelect'] as num?)?.toInt() ?? 0,
        modifiers: ((j['modifiers'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(KioskModifier.fromJson)
            .toList(),
      );

  /// A single required choice (e.g. size) renders as radio buttons; otherwise
  /// the customer can pick several (up to [maxSelect], 0 = unlimited).
  bool get isSingleChoice => maxSelect == 1;
  bool get isRequired => minSelect >= 1;
}

class KioskModifier {
  final String id;
  final String name;
  final int deltaCents;
  final String delta;

  const KioskModifier({
    required this.id,
    required this.name,
    required this.deltaCents,
    required this.delta,
  });

  static KioskModifier fromJson(Map<String, dynamic> j) => KioskModifier(
    id: j['id'] as String,
    name: j['name'] as String,
    deltaCents: (j['deltaCents'] as num?)?.toInt() ?? 0,
    delta: j['delta'] as String? ?? '',
  );
}

/// One line in the kiosk cart: the chosen item, quantity and selected
/// modifiers. Carries snapshots so the cart renders without re-looking-up the
/// menu; only ids + qty are sent back to the POS on submit.
class CartLine {
  final KioskItem item;
  final List<KioskModifier> modifiers;
  int qty;

  CartLine({required this.item, required this.modifiers, this.qty = 1});

  int get unitCents =>
      item.priceCents + modifiers.fold(0, (s, m) => s + m.deltaCents);

  int get lineCents => unitCents * qty;

  /// Two cart lines stack (qty++) when they're the same item with the same
  /// set of modifiers.
  String get signature {
    final ids = modifiers.map((m) => m.id).toList()..sort();
    return '${item.id}|${ids.join(',')}';
  }

  Map<String, dynamic> toSubmitJson() => {
    'itemId': item.id,
    'qty': qty,
    'modifierIds': modifiers.map((m) => m.id).toList(),
  };
}

/// Formats integer cents the same way the POS does on receipts ("$12.34"),
/// without depending on the domain Money type in the sub-window.
String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  return '$sign\$${(abs ~/ 100)}.${(abs % 100).toString().padLeft(2, '0')}';
}
