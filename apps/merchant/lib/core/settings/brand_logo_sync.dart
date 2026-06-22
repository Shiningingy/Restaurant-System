import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import 'brand_logo_store.dart';

/// Syncs the shop's brand logo across devices via the restaurant's own Supabase
/// Storage bucket — the same mechanism as the promo photos, scaled down to one
/// image. The bytes travel content-addressed; a tiny `brand/manifest.json`
/// carries the current choice (or "cleared"). Shop-global, last-write-wins.
class BrandLogoSyncService {
  final domain.ObjectStore store;
  final BrandLogoStore logo;

  /// The device's current logo path (a content-addressed cache file), or null.
  final String? Function() readPath;

  /// Sets the device's logo path (without re-publishing).
  final Future<void> Function(String?) writePath;

  BrandLogoSyncService({
    required this.store,
    required this.logo,
    required this.readPath,
    required this.writePath,
  });

  /// Uploads this device's logo (if any) and rewrites the manifest, making it
  /// the shop-wide one. Call after the owner sets or clears the logo.
  Future<void> publish() async {
    final previous =
        domain.BrandLogoManifest.tryParse(
          await store.getObject(domain.BrandLogoManifest.storageKey) ??
              const [],
        ) ??
        domain.BrandLogoManifest.none;

    final path = readPath();
    final ref = (path == null || path.isEmpty) ? null : logo.refOf(path);
    final manifest = ref == null
        ? domain.BrandLogoManifest.none
        : domain.BrandLogoManifest(sha: ref.sha, ext: ref.ext);

    if (ref != null) {
      await store.putObject(
        manifest.objectKey,
        await logo.bytesOf(path!),
        contentType: _contentType(ref.ext),
      );
    }
    await store.putObject(
      domain.BrandLogoManifest.storageKey,
      manifest.encode(),
      contentType: 'application/json',
    );

    // Remove the previously-published logo object if it's no longer used.
    if (previous.hasLogo && previous.sha != ref?.sha) {
      try {
        await store.deleteObject(previous.objectKey);
      } on Object {
        // Best-effort — a failed delete just leaves a harmless orphan.
      }
    }
  }

  /// Reconciles this device to the published logo: downloads it if missing and
  /// points the device at it, or clears the local logo if it was cleared
  /// remotely. Returns true when the local logo changed. Null manifest (never
  /// published) leaves the device's own logo untouched.
  Future<bool> pull() async {
    final raw = await store.getObject(domain.BrandLogoManifest.storageKey);
    if (raw == null) return false;
    final manifest = domain.BrandLogoManifest.tryParse(raw);
    if (manifest == null) return false;

    if (!manifest.hasLogo) {
      if (readPath() == null) return false; // already none
      await logo.clear();
      await writePath(null);
      return true;
    }

    if (!await logo.hasSha(manifest.sha!)) {
      final bytes = await store.getObject(manifest.objectKey);
      if (bytes == null) return false; // manifest points at a missing object
      await logo.writeBytes(manifest.sha!, manifest.ext!, bytes);
    }
    final newPath = await logo.pathFor(manifest.sha!, manifest.ext!);
    if (readPath() == newPath) return false;
    await writePath(newPath);
    return true;
  }

  static String _contentType(String ext) => switch (ext) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.gif' => 'image/gif',
    _ => 'application/octet-stream',
  };
}
