import 'dart:convert';

/// The payload encoded in a storefront QR code (and decoded when scanning
/// one). A restaurant — or a customer sharing one they've saved — shows this;
/// scanning it adds the restaurant to the wallet.
///
/// It carries only the Supabase URL + anon key (+ optional display name). The
/// anon key is **publishable by design** (RLS guards the data), so a QR is
/// safe to print, share, or pass around like a phone number.
class StorefrontLink {
  /// Bumped if the payload shape ever changes, so old apps reject new codes
  /// cleanly instead of misreading them.
  static const _version = 1;

  final String url;
  final String anonKey;
  final String? name;

  const StorefrontLink({required this.url, required this.anonKey, this.name});

  String encode() => jsonEncode({
    'v': _version,
    'url': url,
    'key': anonKey,
    if (name != null && name!.isNotEmpty) 'name': name,
  });

  /// Parses a scanned/pasted code, or returns null if it isn't a storefront
  /// link we understand (random QR, wrong version, missing fields).
  static StorefrontLink? tryParse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw.trim());
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded['v'] != _version) return null;
    final url = decoded['url'];
    final key = decoded['key'];
    if (url is! String || url.isEmpty || key is! String || key.isEmpty) {
      return null;
    }
    final name = decoded['name'];
    return StorefrontLink(
      url: url,
      anonKey: key,
      name: name is String && name.isNotEmpty ? name : null,
    );
  }
}
