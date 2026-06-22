import 'package:http/http.dart' as http;
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// [domain.ObjectStore] over the restaurant's own Supabase **Storage**.
///
/// Like [SupabaseSyncBackend] this is the only place that knows the Storage
/// wire format. It uses one **private** bucket ([bucket]); its RLS must grant
/// the authenticated restaurant full access and deny the customer-facing anon
/// key entirely (bucket DDL + policies in docs/CLOUD_SECURITY.md — a blocking
/// gate before any live rollout).
///
/// Objects are content-addressed by the caller (`promo/<sha>.jpg`), so writing
/// the same key twice is harmless; uploads use `x-upsert: true` so a re-publish
/// (or the rewritten manifest) just overwrites.
class SupabaseObjectStore implements domain.ObjectStore {
  final Uri baseUrl;
  final String anonKey;
  final String bucket;
  final http.Client _client;
  final Duration timeout;

  /// The signed-in restaurant user's access token (the bucket's RLS denies the
  /// bare anon key); falls back to the anon key when null (tests).
  final Future<String?> Function()? accessToken;

  SupabaseObjectStore({
    required String url,
    required this.anonKey,
    this.bucket = 'pos-assets',
    this.accessToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
       _client = client ?? http.Client();

  Uri _object(String key) =>
      baseUrl.resolve('storage/v1/object/$bucket/$key');

  Future<Map<String, String>> _authHeaders() async {
    final token = await accessToken?.call() ?? anonKey;
    return {'apikey': anonKey, 'Authorization': 'Bearer $token'};
  }

  @override
  Future<void> putObject(
    String key,
    List<int> bytes, {
    required String contentType,
  }) async {
    final resp = await _client
        .post(
          _object(key),
          headers: {
            ...await _authHeaders(),
            'Content-Type': contentType,
            // Create-or-replace: content-addressed keys never change meaning,
            // and the manifest is meant to be overwritten each publish.
            'x-upsert': 'true',
          },
          body: bytes,
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('object upload failed (${resp.statusCode})');
    }
  }

  @override
  Future<List<int>?> getObject(String key) async {
    final resp = await _client
        .get(_object(key), headers: await _authHeaders())
        .timeout(timeout);
    if (resp.statusCode == 200) return resp.bodyBytes;
    // 400/404 — Storage reports a missing object as 400 ("Object not found")
    // or 404 depending on version; both mean "not there", not an error.
    if (resp.statusCode == 400 || resp.statusCode == 404) return null;
    throw domain.SyncException('object fetch failed (${resp.statusCode})');
  }
}
