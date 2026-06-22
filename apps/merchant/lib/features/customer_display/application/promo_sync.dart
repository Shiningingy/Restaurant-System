import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../data/promo_image_store.dart';

/// Syncs the customer-display promo photos across the shop's devices via the
/// restaurant's own Supabase Storage bucket.
///
/// The photo *bytes* travel through [domain.ObjectStore] (content-addressed by
/// SHA-256); the ordered *set* travels as a small `promo/manifest.json`. It's
/// shop-global and last-write-wins: the owner edits the set on one device
/// ([publish]) and every other device reconciles to it on the next sync
/// ([pull]). The row-based sync feed can't carry binary assets, so this runs
/// alongside it — never blocking it (all failures are the caller's to swallow).
class PromoSyncService {
  final domain.ObjectStore store;
  final PromoImageStore images;

  /// The device's current promo photo paths (content-addressed cache files).
  final List<String> Function() readPaths;

  /// Replaces the device's promo photo paths (without re-publishing).
  final Future<void> Function(List<String>) writePaths;

  /// The device's current promo text lines.
  final List<String> Function() readLines;

  /// Replaces the device's promo text lines (without re-publishing).
  final Future<void> Function(List<String>) writeLines;

  PromoSyncService({
    required this.store,
    required this.images,
    required this.readPaths,
    required this.writePaths,
    required this.readLines,
    required this.writeLines,
  });

  /// Uploads this device's promo photos and rewrites the manifest, making this
  /// set the shop-wide one. Call after the owner edits the promo images.
  ///
  /// Photos are content-addressed, so re-publishing the same image just
  /// overwrites its object (no duplicates). A photo the owner *removed* is
  /// deleted from the bucket so orphaned bytes don't accumulate.
  Future<void> publish() async {
    // Snapshot the previously-published set before we overwrite the manifest,
    // so we can clean up what's no longer referenced.
    final previous =
        domain.PromoManifest.tryParse(
          await store.getObject(domain.PromoManifest.storageKey) ?? const [],
        ) ??
        domain.PromoManifest.empty;

    final refs = <domain.PromoImageRef>[];
    for (final path in readPaths()) {
      final ref = images.refOf(path);
      if (ref == null) continue; // not a content-addressed file — skip
      refs.add(ref);
      await store.putObject(
        ref.storageKey,
        await images.bytesOf(path),
        contentType: _contentType(ref.ext),
      );
    }
    await store.putObject(
      domain.PromoManifest.storageKey,
      domain.PromoManifest(refs, lines: readLines()).encode(),
      contentType: 'application/json',
    );

    // Delete photos that were published before but aren't in the new set.
    // Compare by hash so a still-present photo is never removed.
    final keptShas = {for (final r in refs) r.sha};
    for (final old in previous.images) {
      if (!keptShas.contains(old.sha)) {
        try {
          await store.deleteObject(old.storageKey);
        } on Object {
          // Best-effort cleanup — a failed delete just leaves a harmless orphan.
        }
      }
    }
  }

  /// Reconciles this device to the published manifest: downloads any photos it
  /// doesn't have, then points its promo list at the local cache (in manifest
  /// order). Returns the new path list, or null when nothing was published yet
  /// (leave the device's own set untouched).
  Future<List<String>?> pull() async {
    final raw = await store.getObject(domain.PromoManifest.storageKey);
    if (raw == null) return null; // never published — don't disturb local
    final manifest = domain.PromoManifest.tryParse(raw);
    if (manifest == null) return null; // unreadable/newer — leave local alone

    for (final ref in manifest.missingFrom(await images.cachedShas())) {
      final bytes = await store.getObject(ref.storageKey);
      if (bytes != null) await images.writeRef(ref, bytes);
    }

    // Build the new ordered path list from what we actually have cached now.
    final cached = await images.cachedShas();
    final paths = <String>[];
    for (final ref in manifest.images) {
      if (cached.contains(ref.sha)) paths.add(await images.pathFor(ref));
    }
    await writePaths(paths);
    // The promo text rides along in the same manifest.
    await writeLines(manifest.lines);
    return paths;
  }

  static String _contentType(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}
