import 'package:shared_preferences/shared_preferences.dart';

/// The restaurant's storefront the customer connects to — its Supabase
/// URL + anon key (the restaurant shares these, e.g. via a QR code).
class StorefrontConfig {
  final String? url;
  final String? anonKey;

  /// Remembered so repeat orders prefill the customer's details.
  final String? customerName;
  final String? customerPhone;

  const StorefrontConfig({
    this.url,
    this.anonKey,
    this.customerName,
    this.customerPhone,
  });

  bool get isConnected =>
      url != null && url!.isNotEmpty && anonKey != null && anonKey!.isNotEmpty;
}

class StorefrontConfigRepository {
  static const _urlKey = 'storefrontUrl';
  static const _anonKey = 'storefrontAnonKey';
  static const _nameKey = 'customerName';
  static const _phoneKey = 'customerPhone';

  final SharedPreferences prefs;

  StorefrontConfigRepository(this.prefs);

  StorefrontConfig get config => StorefrontConfig(
    url: prefs.getString(_urlKey),
    anonKey: prefs.getString(_anonKey),
    customerName: prefs.getString(_nameKey),
    customerPhone: prefs.getString(_phoneKey),
  );

  Future<void> connect({required String url, required String anonKey}) async {
    await prefs.setString(_urlKey, url.trim());
    await prefs.setString(_anonKey, anonKey.trim());
  }

  Future<void> disconnect() async {
    await prefs.remove(_urlKey);
    await prefs.remove(_anonKey);
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
