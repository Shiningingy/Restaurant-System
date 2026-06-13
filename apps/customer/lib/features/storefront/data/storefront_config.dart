import 'package:shared_preferences/shared_preferences.dart';

/// The restaurant's storefront the customer connects to — its Supabase
/// URL + anon key (the restaurant shares these, e.g. via a QR code).
class StorefrontConfig {
  final String? url;
  final String? anonKey;

  /// Remembered so repeat orders prefill the customer's details.
  final String? customerName;
  final String? customerPhone;

  /// The anonymous Supabase session for this device — its refresh token
  /// (to stay signed in across launches) and uid (to tie preorders to it).
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

class StorefrontConfigRepository {
  static const _urlKey = 'storefrontUrl';
  static const _anonKey = 'storefrontAnonKey';
  static const _nameKey = 'customerName';
  static const _phoneKey = 'customerPhone';
  static const _refreshKey = 'storefrontRefreshToken';
  static const _uidKey = 'storefrontCustomerUid';

  final SharedPreferences prefs;

  StorefrontConfigRepository(this.prefs);

  StorefrontConfig get config => StorefrontConfig(
    url: prefs.getString(_urlKey),
    anonKey: prefs.getString(_anonKey),
    customerName: prefs.getString(_nameKey),
    customerPhone: prefs.getString(_phoneKey),
    sessionRefreshToken: prefs.getString(_refreshKey),
    customerUid: prefs.getString(_uidKey),
  );

  Future<void> connect({required String url, required String anonKey}) async {
    await prefs.setString(_urlKey, url.trim());
    await prefs.setString(_anonKey, anonKey.trim());
  }

  Future<void> saveSession({
    required String refreshToken,
    required String uid,
  }) async {
    await prefs.setString(_refreshKey, refreshToken);
    await prefs.setString(_uidKey, uid);
  }

  Future<void> disconnect() async {
    await prefs.remove(_urlKey);
    await prefs.remove(_anonKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_uidKey);
  }

  Future<void> rememberCustomer({required String name, String? phone}) async {
    await prefs.setString(_nameKey, name);
    if (phone == null || phone.isEmpty) {
      await prefs.remove(_phoneKey);
    } else {
      await prefs.setString(_phoneKey, phone);
    }
  }
}
