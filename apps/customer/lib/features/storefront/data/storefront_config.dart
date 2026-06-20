import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The customer's own details, reused across every restaurant they've saved.
/// This is a **convenience record, not an account** — no password, no login,
/// no server. It only prefills the pickup info on a preorder.
class CustomerProfile {
  final String? name;
  final String? phone;
  final String? email;

  const CustomerProfile({this.name, this.phone, this.email});

  bool get isEmpty =>
      (name == null || name!.isEmpty) &&
      (phone == null || phone!.isEmpty) &&
      (email == null || email!.isEmpty);

  CustomerProfile copyWith({String? name, String? phone, String? email}) =>
      CustomerProfile(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
      );
}

/// One restaurant the customer has collected in their wallet — its Supabase
/// URL + anon key (safe to store/share: the anon key is publishable, RLS
/// guards the data), an optional friendly name, and this device's anonymous
/// session for that restaurant's backend.
class SavedStorefront {
  final String id;
  final String url;
  final String anonKey;

  /// Display name shown in the wallet; falls back to the URL host.
  final String? name;

  /// The device's anonymous Supabase session for *this* storefront.
  final String? sessionRefreshToken;
  final String? customerUid;

  const SavedStorefront({
    required this.id,
    required this.url,
    required this.anonKey,
    this.name,
    this.sessionRefreshToken,
    this.customerUid,
  });

  /// A human label even when no name was given: the URL host (e.g. the
  /// Supabase project ref) so each saved restaurant is still distinguishable.
  String get label {
    if (name != null && name!.isNotEmpty) return name!;
    final host = Uri.tryParse(url)?.host;
    return (host == null || host.isEmpty) ? url : host;
  }

  SavedStorefront copyWith({
    String? name,
    String? sessionRefreshToken,
    String? customerUid,
  }) => SavedStorefront(
    id: id,
    url: url,
    anonKey: anonKey,
    name: name ?? this.name,
    sessionRefreshToken: sessionRefreshToken ?? this.sessionRefreshToken,
    customerUid: customerUid ?? this.customerUid,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'anonKey': anonKey,
    if (name != null && name!.isNotEmpty) 'name': name,
    if (sessionRefreshToken != null) 'refresh': sessionRefreshToken,
    if (customerUid != null) 'uid': customerUid,
  };

  factory SavedStorefront.fromJson(Map<String, dynamic> j) => SavedStorefront(
    id: j['id'] as String,
    url: j['url'] as String,
    anonKey: j['anonKey'] as String,
    name: j['name'] as String?,
    sessionRefreshToken: j['refresh'] as String?,
    customerUid: j['uid'] as String?,
  );
}

/// The whole device-local wallet: the customer's profile plus every saved
/// restaurant and which one is currently open.
class Wallet {
  final CustomerProfile profile;
  final List<SavedStorefront> storefronts;
  final String? activeId;

  const Wallet({
    required this.profile,
    this.storefronts = const [],
    this.activeId,
  });

  SavedStorefront? get active {
    if (activeId == null) return null;
    for (final s in storefronts) {
      if (s.id == activeId) return s;
    }
    return null;
  }

  /// True when a restaurant is open (we're inside its menu/ordering flow).
  bool get isConnected => active != null;
}

/// A read-only view of the active storefront merged with the customer
/// profile — kept stable so the menu/cart/status flow is untouched by the
/// wallet refactor.
class StorefrontConfig {
  final String? url;
  final String? anonKey;
  final String? customerName;
  final String? customerPhone;
  final String? sessionRefreshToken;
  final String? customerUid;

  const StorefrontConfig({
    this.url,
    this.anonKey,
    this.customerName,
    this.customerPhone,
    this.sessionRefreshToken,
    this.customerUid,
  });

  bool get isConnected =>
      url != null && url!.isNotEmpty && anonKey != null && anonKey!.isNotEmpty;
}

/// Device-local persistence for the wallet (saved restaurants + the customer
/// profile). Backed by [SharedPreferences]; nothing here is synced — the
/// wallet is private to the device.
class StorefrontConfigRepository {
  static const _storefrontsKey = 'walletStorefronts';
  static const _activeKey = 'walletActiveId';
  static const _nameKey = 'customerName';
  static const _phoneKey = 'customerPhone';
  static const _emailKey = 'customerEmail';
  static const _appLocaleKey = 'appLocale';

  // Pre-wallet single-storefront keys, migrated forward on first write.
  static const _legacyUrlKey = 'storefrontUrl';
  static const _legacyAnonKey = 'storefrontAnonKey';
  static const _legacyRefreshKey = 'storefrontRefreshToken';
  static const _legacyUidKey = 'storefrontCustomerUid';
  static const _legacyId = 'legacy';

  final SharedPreferences prefs;

  StorefrontConfigRepository(this.prefs);

  /// Preferred UI language code ('en' / 'zh'), or null to follow the system.
  String? get appLocaleCode => prefs.getString(_appLocaleKey);

  Future<void> setAppLocaleCode(String? code) => code == null
      ? prefs.remove(_appLocaleKey)
      : prefs.setString(_appLocaleKey, code);

  CustomerProfile get profile => CustomerProfile(
    name: prefs.getString(_nameKey),
    phone: prefs.getString(_phoneKey),
    email: prefs.getString(_emailKey),
  );

  /// Every restaurant in the wallet. Reads forward from the new list, or
  /// synthesizes a single entry from the pre-wallet keys (legacy users).
  List<SavedStorefront> get storefronts {
    final raw = prefs.getString(_storefrontsKey);
    if (raw != null) {
      final decoded = (jsonDecode(raw) as List)
          .map((e) => SavedStorefront.fromJson(e as Map<String, dynamic>))
          .toList();
      return decoded;
    }
    final legacyUrl = prefs.getString(_legacyUrlKey);
    final legacyAnon = prefs.getString(_legacyAnonKey);
    if (legacyUrl != null &&
        legacyUrl.isNotEmpty &&
        legacyAnon != null &&
        legacyAnon.isNotEmpty) {
      return [
        SavedStorefront(
          id: _legacyId,
          url: legacyUrl,
          anonKey: legacyAnon,
          sessionRefreshToken: prefs.getString(_legacyRefreshKey),
          customerUid: prefs.getString(_legacyUidKey),
        ),
      ];
    }
    return const [];
  }

  String? get activeStorefrontId {
    final id = prefs.getString(_activeKey);
    if (id != null) return id;
    // Legacy users were always "connected" to their single storefront.
    if (prefs.getString(_storefrontsKey) == null) {
      final legacyUrl = prefs.getString(_legacyUrlKey);
      if (legacyUrl != null && legacyUrl.isNotEmpty) return _legacyId;
    }
    return null;
  }

  Wallet get wallet => Wallet(
    profile: profile,
    storefronts: storefronts,
    activeId: activeStorefrontId,
  );

  Future<void> _persist(List<SavedStorefront> list, String? activeId) async {
    await prefs.setString(
      _storefrontsKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    await _setOrRemove(_activeKey, activeId);
    // Now that the wallet owns the data, retire the pre-wallet keys.
    await prefs.remove(_legacyUrlKey);
    await prefs.remove(_legacyAnonKey);
    await prefs.remove(_legacyRefreshKey);
    await prefs.remove(_legacyUidKey);
  }

  /// Adds a restaurant (or updates the one with the same URL) and makes it
  /// active. The session is captured here so reopening it later needs no
  /// re-auth.
  Future<SavedStorefront> addStorefront({
    required String url,
    required String anonKey,
    String? name,
    String? refreshToken,
    String? uid,
  }) async {
    final list = storefronts.toList();
    final normUrl = url.trim();
    final existing = list.indexWhere((s) => s.url == normUrl);
    final id = existing >= 0
        ? list[existing].id
        : DateTime.now().microsecondsSinceEpoch.toString();
    final entry = SavedStorefront(
      id: id,
      url: normUrl,
      anonKey: anonKey.trim(),
      name: (name == null || name.trim().isEmpty) ? null : name.trim(),
      sessionRefreshToken: refreshToken,
      customerUid: uid,
    );
    if (existing >= 0) {
      list[existing] = entry;
    } else {
      list.add(entry);
    }
    await _persist(list, id);
    return entry;
  }

  /// Opens a saved restaurant (or `null` to return to the wallet).
  Future<void> setActive(String? id) async =>
      _persist(storefronts.toList(), id);

  Future<void> removeStorefront(String id) async {
    final list = storefronts.where((s) => s.id != id).toList();
    final active = activeStorefrontId == id ? null : activeStorefrontId;
    await _persist(list, active);
  }

  /// Updates the active storefront's stored session.
  Future<void> saveSession({
    required String refreshToken,
    required String uid,
  }) async {
    final id = activeStorefrontId;
    if (id == null) return;
    final list = storefronts
        .map(
          (s) => s.id == id
              ? s.copyWith(sessionRefreshToken: refreshToken, customerUid: uid)
              : s,
        )
        .toList();
    await _persist(list, id);
  }

  Future<void> saveProfile(CustomerProfile p) async {
    await _setOrRemove(_nameKey, p.name);
    await _setOrRemove(_phoneKey, p.phone);
    await _setOrRemove(_emailKey, p.email);
  }

  /// Remembers the name/phone the customer typed at checkout for next time.
  Future<void> rememberCustomer({required String name, String? phone}) async {
    await _setOrRemove(_nameKey, name);
    await _setOrRemove(_phoneKey, phone);
  }

  Future<void> _setOrRemove(String key, String? value) =>
      (value == null || value.isEmpty)
      ? prefs.remove(key)
      : prefs.setString(key, value);
}
