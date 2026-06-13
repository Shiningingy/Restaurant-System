import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// A signed-in Supabase session.
class SupabaseSession {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final bool isAnonymous;
  final DateTime expiresAt;

  const SupabaseSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.isAnonymous,
    required this.expiresAt,
  });

  bool get isExpiring =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));
}

/// Minimal GoTrue (Supabase Auth) client over raw HTTP — enough to sign
/// the merchant tablet in as a real restaurant user and carry a valid
/// access token on every PostgREST request, so RLS can tell the
/// restaurant apart from customers (docs/CLOUD_SECURITY.md).
///
/// The only place the merchant app talks to Supabase Auth.
class SupabaseAuth {
  final Uri baseUrl;
  final String anonKey;
  final http.Client _client;
  final Duration timeout;

  SupabaseSession? _session;

  SupabaseAuth({
    required String url,
    required this.anonKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
       _client = client ?? http.Client();

  SupabaseSession? get session => _session;

  Uri _auth(String path, [Map<String, dynamic>? query]) => baseUrl
      .resolve('auth/v1/$path')
      .replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));

  Map<String, String> get _headers => {
    'apikey': anonKey,
    'Content-Type': 'application/json',
  };

  Future<SupabaseSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final resp = await _client
        .post(
          _auth('token', {'grant_type': 'password'}),
          headers: _headers,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(timeout);
    return _session = _parse(resp);
  }

  Future<SupabaseSession> signInAnonymously() async {
    final resp = await _client
        .post(_auth('signup'), headers: _headers, body: jsonEncode({}))
        .timeout(timeout);
    return _session = _parse(resp);
  }

  /// Restores a persisted session (e.g. across app launches) without a
  /// round-trip; the token is refreshed lazily by [accessToken].
  void restore(SupabaseSession session) => _session = session;

  void signOut() => _session = null;

  /// A currently-valid access token, refreshing if near expiry. Null when
  /// signed out — callers then fall back to the anon key.
  Future<String?> accessToken() async {
    final current = _session;
    if (current == null) return null;
    if (current.isExpiring) {
      final refreshed = await _refresh(current.refreshToken);
      return refreshed.accessToken;
    }
    return current.accessToken;
  }

  Future<SupabaseSession> _refresh(String refreshToken) async {
    final resp = await _client
        .post(
          _auth('token', {'grant_type': 'refresh_token'}),
          headers: _headers,
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(timeout);
    return _session = _parse(resp);
  }

  SupabaseSession _parse(http.Response resp) {
    if (resp.statusCode >= 300) {
      throw domain.SyncException('auth failed (${resp.statusCode})');
    }
    final j = jsonDecode(resp.body) as Map<String, dynamic>;
    final user = j['user'] as Map<String, dynamic>;
    return SupabaseSession(
      accessToken: j['access_token'] as String,
      refreshToken: j['refresh_token'] as String,
      userId: user['id'] as String,
      isAnonymous: user['is_anonymous'] as bool? ?? false,
      expiresAt: DateTime.now().add(
        Duration(seconds: (j['expires_in'] as num).toInt()),
      ),
    );
  }
}
