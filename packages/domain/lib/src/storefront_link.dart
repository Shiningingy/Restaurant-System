import 'dart:convert';

/// The connection a customer needs to reach a restaurant's storefront,
/// encoded for a QR code (or link). The merchant app shows one; the customer
/// app scans it to add the restaurant to their wallet.
///
/// It carries only the Supabase URL + anon key (+ optional display name). The
/// anon key is **publishable by design** — RLS guards the data — so a QR is
/// safe to print, display, or pass around like a phone number. This is the
/// single source of truth for the wire format, shared by both apps.
class StorefrontLink {
  /// Bumped if the payload shape ever changes, so an older app rejects a
  /// newer code cleanly instead of misreading it.
  static const int version = 1;

  final String url;
  final String anonKey;
  final String? name;

  const StorefrontLink({required this.url, required this.anonKey, this.name});

  String encode() => jsonEncode({
        'v': version,
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
    if (decoded['v'] != version) return null;
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
