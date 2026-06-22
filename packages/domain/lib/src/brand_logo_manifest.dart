import 'dart:convert';

/// The shop's brand logo, published to Storage as `brand/manifest.json`.
///
/// Like the promo manifest it's shop-global and last-write-wins, but it carries
/// at most one image (content-addressed by SHA-256). A manifest with no
/// [sha]/[ext] means the owner cleared the logo — other devices should drop
/// their copy too (distinct from "never published", which is a missing object).
class BrandLogoManifest {
  static const version = 1;
  static const storageKey = 'brand/manifest.json';

  /// Lowercase hex SHA-256 of the logo bytes, or null when there's no logo.
  final String? sha;

  /// File extension including the leading dot (e.g. `.png`), or null.
  final String? ext;

  const BrandLogoManifest({this.sha, this.ext});

  static const none = BrandLogoManifest();

  bool get hasLogo => sha != null && sha!.isNotEmpty && ext != null;

  /// The object key in the assets bucket: `brand/<sha><ext>`.
  String get objectKey => 'brand/$sha$ext';

  /// The content-addressed cache file name: `<sha><ext>`.
  String get fileName => '$sha$ext';

  static BrandLogoManifest? tryParse(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (json['version'] != version) return null;
      return BrandLogoManifest(
        sha: json['sha'] as String?,
        ext: json['ext'] as String?,
      );
    } on Object {
      return null;
    }
  }

  List<int> encode() =>
      utf8.encode(jsonEncode({'version': version, 'sha': sha, 'ext': ext}));
}
