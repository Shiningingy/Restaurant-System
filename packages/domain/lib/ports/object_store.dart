/// Optional remote blob storage — the restaurant's own Supabase **Storage**
/// bucket — for binary assets the row-based sync feed ([SyncBackend]) can't
/// carry, e.g. promo photos shown on the customer display.
///
/// Like [SyncBackend], the local device is always usable without it: when the
/// cloud isn't configured the app uses a no-op store and assets stay
/// device-local. Keys are caller-defined paths within a single private bucket
/// (e.g. `promo/<sha>.jpg`); the implementation knows the wire format.
abstract interface class ObjectStore {
  /// Uploads [bytes] at [key], creating or replacing (idempotent). [contentType]
  /// is the MIME type (e.g. `image/jpeg`, `application/json`).
  Future<void> putObject(
    String key,
    List<int> bytes, {
    required String contentType,
  });

  /// Fetches the object at [key], or null when it doesn't exist.
  Future<List<int>?> getObject(String key);

  /// Removes the object at [key]. A no-op if it's already gone (so callers can
  /// delete optimistically without checking first).
  Future<void> deleteObject(String key);
}
