import 'dart:convert';

/// One promo photo, identified by the SHA-256 hash of its bytes (content
/// addressing) plus its file extension. The hash makes the storage key stable
/// and uploads idempotent: the same photo always maps to the same object, so
/// re-publishing dedupes and every device can tell whether it already has a
/// copy without downloading it.
class PromoImageRef {
  /// Lowercase hex SHA-256 of the image bytes.
  final String sha;

  /// File extension including the leading dot, lowercased (e.g. `.jpg`).
  final String ext;

  const PromoImageRef({required this.sha, required this.ext});

  /// The object key within the assets bucket: `promo/<sha><ext>`.
  String get storageKey => 'promo/$sha$ext';

  /// The content-addressed cache file name: `<sha><ext>`.
  String get fileName => '$sha$ext';

  factory PromoImageRef.fromJson(Map<String, dynamic> json) => PromoImageRef(
    sha: json['sha'] as String,
    ext: json['ext'] as String,
  );

  Map<String, dynamic> toJson() => {'sha': sha, 'ext': ext};

  @override
  bool operator ==(Object other) =>
      other is PromoImageRef && other.sha == sha && other.ext == ext;

  @override
  int get hashCode => Object.hash(sha, ext);
}

/// The ordered set of promo photos for a shop, published to Storage as
/// `promo/manifest.json`. It is *shop-global* (one set, last-write-wins): the
/// owner edits it on their device and every other device reconciles to it on
/// sync. The order is the slideshow order.
class PromoManifest {
  /// Bumped if the on-the-wire shape ever changes, so an older app can refuse
  /// a manifest it can't read rather than mis-parse it.
  static const version = 1;

  /// The fixed object key the manifest lives at.
  static const storageKey = 'promo/manifest.json';

  final List<PromoImageRef> images;

  /// The idle-screen promo text lines, synced alongside the photos so an
  /// owner's wording reaches every device (not just this one).
  final List<String> lines;

  const PromoManifest(this.images, {this.lines = const []});

  static const empty = PromoManifest([]);

  /// Parses a manifest from raw JSON bytes, or null if it's malformed or a
  /// newer version this build doesn't understand. `lines` is optional so a
  /// manifest written before text-sync existed still parses (no lines).
  static PromoManifest? tryParse(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (json['version'] != version) return null;
      final list = (json['images'] as List).cast<Map<String, dynamic>>();
      final lines =
          (json['lines'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];
      return PromoManifest(
        [for (final m in list) PromoImageRef.fromJson(m)],
        lines: lines,
      );
    } on Object {
      return null;
    }
  }

  List<int> encode() => utf8.encode(
    jsonEncode({
      'version': version,
      'images': [for (final r in images) r.toJson()],
      'lines': lines,
    }),
  );

  /// The refs in this manifest that aren't present in [localShas] — i.e. the
  /// photos a device must download from Storage before it can show them.
  List<PromoImageRef> missingFrom(Set<String> localShas) =>
      [for (final r in images) if (!localShas.contains(r.sha)) r];
}
