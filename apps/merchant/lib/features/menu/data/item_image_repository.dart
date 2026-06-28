import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import '../../../core/sync/sync_codec.dart' show SyncEntities;
import '../../../core/sync/sync_journal.dart';
import 'item_image_store.dart';

/// A renamable image attached to a menu item. [sha]/[ext] are the content
/// address used to sync the bytes across the shop's devices (null on a legacy
/// row until the backfill computes it); [path] is the local file, empty on a
/// synced row whose bytes haven't been downloaded yet.
class ItemImage {
  final String id;
  final String itemId;
  final String label;
  final String path;
  final String? sha;
  final String? ext;
  final int sortOrder;

  const ItemImage({
    required this.id,
    required this.itemId,
    required this.label,
    required this.path,
    required this.sortOrder,
    this.sha,
    this.ext,
  });
}

/// DB rows for item images plus the on-disk file lifecycle, and the cross-device
/// sync of the bytes. The image *refs* `(sha, ext)` ride the normal change feed
/// as part of the `menu_item` aggregate (so a photo change re-journals its item);
/// the *bytes* travel through the public **`menu-photos`** Storage bucket,
/// content-addressed as `<sha><ext>`. Kept separate from [MenuRepository]
/// because images are binary.
class ItemImageRepository {
  final AppDatabase db;
  final ItemImageStore store;
  final SyncJournal journal;

  /// The `menu-photos` bucket. Null when the cloud isn't configured (tests /
  /// offline) — images then stay purely local.
  final domain.ObjectStore? objectStore;

  ItemImageRepository(
    this.db, {
    ItemImageStore? store,
    SyncJournal? journal,
    this.objectStore,
  }) : store = store ?? ItemImageStore(),
       journal = journal ?? SyncJournal(db);

  Stream<List<ItemImage>> watchImages(String itemId) {
    final q = db.select(db.menuItemImages)
      ..where((t) => t.itemId.equals(itemId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.watch().map((rows) => rows.map(_toImage).toList());
  }

  ItemImage _toImage(MenuItemImageRow r) => ItemImage(
    id: r.id,
    itemId: r.itemId,
    label: r.label,
    path: r.path,
    sha: r.sha,
    ext: r.ext,
    sortOrder: r.sortOrder,
  );

  /// Copies [sourcePath] into app storage (content-addressed), records the row
  /// with its `(sha, ext)`, uploads the bytes (best-effort), and re-journals the
  /// item so the photo ref syncs. A failed upload isn't fatal — re-add the photo
  /// if it never reaches the cloud (offline at add time).
  Future<void> addImage({
    required String itemId,
    required String label,
    required String sourcePath,
  }) async {
    final stored = await store.import(sourcePath);
    final count = await (db.select(
      db.menuItemImages,
    )..where((t) => t.itemId.equals(itemId))).get().then((r) => r.length);
    await db
        .into(db.menuItemImages)
        .insert(
          MenuItemImagesCompanion.insert(
            id: domain.newId(),
            itemId: itemId,
            label: label,
            path: stored.path,
            sha: Value(stored.sha),
            ext: Value(stored.ext),
            sortOrder: Value(count),
          ),
        );
    await _upload(stored.sha, stored.ext, stored.path);
    await journal.recordUpsert(SyncEntities.menuItem, itemId);
  }

  Future<void> renameImage(String id, String label) async {
    final row = await (db.select(
      db.menuItemImages,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (db.update(db.menuItemImages)..where((t) => t.id.equals(id))).write(
      MenuItemImagesCompanion(label: Value(label)),
    );
    await journal.recordUpsert(SyncEntities.menuItem, row.itemId);
  }

  Future<void> deleteImage(String id) async {
    final row = await (db.select(
      db.menuItemImages,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (db.delete(db.menuItemImages)..where((t) => t.id.equals(id))).go();
    await journal.recordUpsert(SyncEntities.menuItem, row.itemId);
    if (row.path.isEmpty) return;
    // Content-addressed: only drop the local file when no other row still points
    // at the same bytes. The bucket object is left as a harmless orphan (another
    // device may still reference it until it syncs), matching promo cleanup.
    if (row.sha != null && await _shaStillUsed(row.sha!)) return;
    await store.delete(row.path);
  }

  Future<bool> _shaStillUsed(String sha) async {
    final rows = await (db.select(
      db.menuItemImages,
    )..where((t) => t.sha.equals(sha))).get();
    return rows.isNotEmpty;
  }

  /// Reconciles this device's item photos with the cloud, best-effort, one pass
  /// over every image row (a failure on one never blocks the others):
  ///  - **legacy** rows (no sha) get their hash computed from the local file,
  ///    uploaded, and the item re-journalled so the ref syncs next cycle;
  ///  - rows that arrived via **sync** (empty path) get their bytes downloaded
  ///    by `(sha, ext)` and a local file written.
  /// Already-uploaded local rows are left alone (no per-sync network). Wired into
  /// the sync cycle alongside promo-photo sync; no-op without cloud.
  Future<void> reconcile() async {
    if (objectStore == null) return;
    final rows = await db.select(db.menuItemImages).get();
    for (final r in rows) {
      try {
        await _reconcileRow(r);
      } on Object {
        // Best-effort per photo — skip this one, keep going.
      }
    }
  }

  Future<void> _reconcileRow(MenuItemImageRow r) async {
    // Have the file locally but no hash → legacy row: hash it, upload, re-journal.
    if (r.path.isNotEmpty) {
      if (r.sha == null || r.ext == null) {
        final imported = await store.import(r.path);
        await (db.update(
          db.menuItemImages,
        )..where((t) => t.id.equals(r.id))).write(
          MenuItemImagesCompanion(
            sha: Value(imported.sha),
            ext: Value(imported.ext),
          ),
        );
        await _upload(imported.sha, imported.ext, imported.path);
        await journal.recordUpsert(SyncEntities.menuItem, r.itemId);
      }
      return; // already-hashed local rows were uploaded at add time
    }

    // Synced row with no local file yet → download the bytes by hash.
    final sha = r.sha;
    final ext = r.ext;
    if (sha == null || ext == null) return;
    if (await store.hasSha(sha)) {
      final path = await store.pathFor(sha, ext);
      await (db.update(db.menuItemImages)..where((t) => t.id.equals(r.id)))
          .write(MenuItemImagesCompanion(path: Value(path)));
      return;
    }
    final bytes = await objectStore!.getObject('$sha$ext');
    if (bytes == null) return; // source device hasn't uploaded it yet
    final path = await store.writeBytes(sha, ext, bytes);
    await (db.update(db.menuItemImages)..where((t) => t.id.equals(r.id))).write(
      MenuItemImagesCompanion(path: Value(path)),
    );
  }

  /// Uploads the file's bytes to the bucket (content-addressed key, idempotent).
  Future<void> _upload(String sha, String ext, String path) async {
    final cloud = objectStore;
    if (cloud == null) return;
    try {
      final bytes = await store.bytesOf(path);
      if (bytes == null) return;
      await cloud.putObject('$sha$ext', bytes, contentType: _contentType(ext));
    } on Object {
      // Best-effort — re-add the photo if it never reaches the cloud.
    }
  }

  static String _contentType(String ext) => switch (ext.toLowerCase()) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.gif' => 'image/gif',
    _ => 'application/octet-stream',
  };
}
